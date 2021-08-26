//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public final class Guarantee<T>: Thenable {
    public typealias Value = T
    public private(set) var isSealed = false
    public private(set) var result: T? {
        didSet { result.map(sealResult) }
    }
    public var currentQueue: DispatchQueue?

    public init(on initialQueue: DispatchQueue) {
        self.currentQueue = initialQueue
    }

    public convenience init(result: Value) {
        self.init()
        self.result = result
    }

    public convenience init() {
        self.init(on: .global())
    }

    public convenience init(
        on queue: DispatchQueue,
        _ block: @escaping () -> Value
    ) {
        self.init(on: queue)
        queue.async {
            self.resolve(block())
        }
    }

    public convenience init<T: Thenable>(
        on queue: DispatchQueue,
        _ block: @escaping () -> T
    ) where T.Value == Value {
        self.init(on: queue)
        queue.async {
            self.resolve(on: queue, with: block())
        }
    }

    private var observers = [(Result) -> Void]()
    private let observerLock = UnfairLock()
    public func observe(_ block: @escaping (Promise<Value>.Result) -> Void) {
        observerLock.withLock {
            if let result = result {
                // If the current queue is defined, ensure
                // we run the block on it. Normally, promise
                // chains run on the same queue as the previous
                // element in the chain *without* an async dispatch
                // for performance reasons, but if the observer is
                // added *after* the promise has finished, we need
                // to dispatch to the correct queue.
                if let currentQueue = currentQueue {
                    currentQueue.async { block(.success(result)) }
                } else {
                    block(.success(result))
                }
                return
            }
            observers.append(block)
        }
    }

    private func sealResult(_ result: T) {
        observerLock.withLock {
            guard !isSealed else { return }
            isSealed = true
            observers.forEach { $0(.success(result)) }
            observers.removeAll()
        }
    }

    public func resolve(_ value: Value) {
        sealResult(value)
    }

    public func resolve<T: Thenable>(
        on queue: DispatchQueue?,
        with thenable: T
    ) where T.Value == Value {
        thenable.done { value in
            self.sealResult(value)
        }
    }
}

public extension Guarantee {
    func wait() throws -> T {
        var result = self.result

        if result == nil {
            let group = DispatchGroup()
            group.enter()
            observe {
                guard case .success(let value) = $0 else { return }
                result = value
                group.leave()
            }
            group.wait()
        }

        return result!
    }
}
