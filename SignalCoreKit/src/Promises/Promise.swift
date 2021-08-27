//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public final class Promise<T>: Thenable, Catchable {
    public typealias Value = T
    public let future: Future<Value>
    public var currentQueue: DispatchQueue? {
        get { future.currentQueue }
        set { future.currentQueue = newValue }
    }
    public var result: Promise<Value>.Result? { future.result }
    public var isSealed: Bool { future.isSealed }

    public init(on initialQueue: DispatchQueue? = nil, future: Future<Value> = Future()) {
        self.future = future
        self.currentQueue = initialQueue
    }

    public convenience init() {
        self.init(future: Future())
    }

    public convenience init(value: Value) {
        self.init(future: Future(value: value))
    }

    public convenience init(error: Error) {
        self.init(future: Future(error: error))
    }

    public convenience init(
        on queue: DispatchQueue,
        _ block: @escaping (Future<Value>) -> Void
    ) {
        self.init(on: queue)
        queue.async { block(self.future) }
    }

    public convenience init(
        on queue: DispatchQueue,
        _ block: @escaping () throws -> Value
    ) {
        self.init(on: queue)
        queue.async {
            do {
                self.resolve(try block())
            } catch {
                self.reject(error)
            }
        }
    }

    public convenience init(
        onCurrent queue: DispatchQueue,
        _ block: @escaping () throws -> Value
    ) {
        self.init(on: queue)
        do {
            resolve(try block())
        } catch {
            reject(error)
        }
    }

    public convenience init<T: Thenable>(
        on queue: DispatchQueue,
        _ block: @escaping () throws -> T
    ) where T.Value == Value {
        self.init(on: queue)
        queue.async {
            do {
                self.resolve(on: queue, with: try block())
            } catch {
                self.reject(error)
            }
        }
    }

    public convenience init<T: Thenable>(
        onCurrent queue: DispatchQueue,
        _ block: @escaping () throws -> T
    ) where T.Value == Value {
        self.init(on: queue)
        do {
            resolve(on: queue, with: try block())
        } catch {
            reject(error)
        }
    }

    public func observe(_ block: @escaping (Promise<Value>.Result) -> Void) {
        future.observe(block)
    }

    public func resolve(_ value: Value) { future.resolve(value) }

    public func resolve<T: Thenable>(
        on queue: DispatchQueue? = nil,
        with thenable: T
    ) where T.Value == Value {
        future.resolve(on: queue, with: thenable)
    }

    public func reject(_ error: Error) { future.reject(error) }
}

public extension Promise {
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

public extension Promise {
    class func pending() -> (Promise<T>, Future<T>) {
        let promise = Promise<T>()
        return (promise, promise.future)
    }
}

public extension Guarantee {
    func asPromise() -> Promise<Value> {
        let promise = Promise<Value>()
        observe { result in
            switch result {
            case .success(let value):
                promise.resolve(value)
            case .failure(let error):
                owsFail("Unexpectedly received error result from unfailable promise \(error)")
            }
        }
        return promise
    }
}
