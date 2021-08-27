//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public final class Future<Value> {
    public typealias Result = Swift.Result<Value, Error>
    public private(set) var isSealed = false
    public private(set) var result: Result?
    public var currentQueue: DispatchQueue?

    public init(on initialQueue: DispatchQueue = .global()) {
        self.currentQueue = initialQueue
    }

    public convenience init(value: Value) {
        self.init()
        sealResult(.success(value))
    }

    public convenience init(error: Error) {
        self.init()
        sealResult(.failure(error))
    }

    private var observers = [(Result) -> Void]()
    private let observerLock = UnfairLock()
    public func observe(_ block: @escaping (Result) -> Void) {
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
                    currentQueue.async { block(result) }
                } else {
                    block(result)
                }
                return
            }
            observers.append(block)
        }
    }
    private func sealResult(_ result: Result) {
        observerLock.withLock {
            guard !isSealed else { return }
            self.result = result
            self.isSealed = true
            observers.forEach { $0(result) }
            observers.removeAll()
        }
    }

    public func resolve(_ value: Value) {
        sealResult(.success(value))
    }

    public func resolve<T: Thenable>(
        on queue: DispatchQueue? = nil,
        with thenable: T
    ) where T.Value == Value {
        if let promise = thenable as? Promise<Value> {
            promise.done(on: queue) { value in
                self.sealResult(.success(value))
            }.catch { error in
                self.sealResult(.failure(error))
            }
        } else {
            thenable.done(on: queue) { value in
                self.sealResult(.success(value))
            }
        }
    }

    public func reject(_ error: Error) {
        sealResult(.failure(error))
    }
}
