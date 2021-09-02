//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public enum PromiseError: String, Error {
    case cancelled
}

public final class Promise<Value>: Thenable, Catchable {
    public let future: Future<Value>
    public var result: Result<Value, Error>? { future.result }
    public var isSealed: Bool { future.isSealed }

    public init(future: Future<Value> = Future()) {
        self.future = future
    }

    public convenience init() {
        self.init(future: Future())
    }

    public static func value(_ value: Value) -> Self {
        let promise = Self()
        promise.resolve(value)
        return promise
    }

    public convenience init(error: Error) {
        self.init(future: Future(error: error))
    }

    public convenience init(
        _ block: (Future<Value>) throws -> Void
    ) {
        self.init()
        do {
            try block(self.future)
        } catch {
            self.reject(error)
        }
    }

    public convenience init(
        on queue: DispatchQueue,
        _ block: @escaping (Future<Value>) throws -> Void
    ) {
        self.init()
        queue.asyncIfNecessary {
            do {
                try block(self.future)
            } catch {
                self.reject(error)
            }
        }
    }

    public func observe(on queue: DispatchQueue? = nil, block: @escaping (Result<Value, Error>) -> Void) {
        future.observe(on: queue, block: block)
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
    func wait() throws -> Value {
        var result = future.result

        if result == nil {
            let group = DispatchGroup()
            group.enter()
            observe(on: .global()) { result = $0; group.leave() }
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
    class func pending() -> (Promise<Value>, Future<Value>) {
        let promise = Promise<Value>()
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
