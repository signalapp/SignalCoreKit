//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public final class Guarantee<T>: Thenable {
    public typealias Value = T
    public let future: Future<Value>
    public var currentQueue: DispatchQueue? {
        get { future.currentQueue }
        set { future.currentQueue = newValue }
    }
    public var result: Promise<Value>.Result? { future.result }
    public var isSealed: Bool { future.isSealed }

    public init(on initialQueue: DispatchQueue) {
        self.future = Future(on: initialQueue)
    }

    public convenience init(value: Value) {
        self.init()
        resolve(value)
    }

    public convenience init() {
        self.init(on: .global())
    }

    public convenience init(
        on queue: DispatchQueue = .current,
        _ block: @escaping () -> Value
    ) {
        self.init(on: queue)
        queue.asyncIfNecessary {
            self.resolve(block())
        }
    }

    public convenience init<T: Thenable>(
        on queue: DispatchQueue = .current,
        _ block: @escaping () -> T
    ) where T.Value == Value {
        self.init(on: queue)
        queue.asyncIfNecessary {
            self.resolve(on: queue, with: block())
        }
    }

    public func observe(on queue: DispatchQueue? = nil, block: @escaping (Promise<Value>.Result) -> Void) {
        future.observe(on: queue, block: block)
    }

    public func resolve(_ value: Value) {
        future.resolve(value)
    }

    public func resolve<T: Thenable>(
        on queue: DispatchQueue?,
        with thenable: T
    ) where T.Value == Value {
        future.resolve(on: queue, with: thenable)
    }
}

public extension Guarantee {
    func wait() throws -> T {
        var result = future.result

        if result == nil {
            let group = DispatchGroup()
            group.enter()
            observe { result = $0; group.leave() }
            group.wait()
        }

        switch result! {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
