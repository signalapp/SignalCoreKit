//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public protocol Thenable: AnyObject {
    associatedtype Value
    typealias Result = Swift.Result<Value, Error>
    init()
    var currentQueue: DispatchQueue? { get set }
    func observe(_ block: @escaping (Result) -> Void)
    func resolve(_ value: Value)
    func resolve<T: Thenable>(on queue: DispatchQueue?, with thenable: T) where T.Value == Value
}

public extension Thenable {
    func map<T>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) -> T
    ) -> Guarantee<T> {
        observe(on: queue, block: block)
    }

    @discardableResult
    func done(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) -> Void
    ) -> Guarantee<Void> {
        observe(on: queue, block: block)
    }

    @discardableResult
    func then<T>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) -> Guarantee<T>
    ) -> Guarantee<T> {
        observe(on: queue, block: block)
    }

    func then<T>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) -> Promise<T>
    ) -> Promise<T> {
        observe(on: queue, block: block)
    }

    func asVoid() -> Guarantee<Void> {
        map { _ in }
    }
}

fileprivate extension Thenable {
    func observe<T>(
        on queue: DispatchQueue?,
        block: @escaping (Value) -> T
    ) -> Guarantee<T> {
        let gurantee = Guarantee<T>()
        observe { result in
            if let queue = queue { gurantee.currentQueue = queue }
            switch result {
            case .success(let value):
                // Only perform an async dispatch if we're not
                // already on the correct queue.
                if let queue = queue, queue != self.currentQueue {
                    queue.async {
                        gurantee.resolve(block(value))
                    }
                } else {
                    gurantee.resolve(block(value))
                }
            case .failure(let error):
                owsFail("Unexpectedly received error result from unfailable promise \(error)")
            }
        }
        return gurantee
    }

    func observe<T>(
        on queue: DispatchQueue?,
        block: @escaping (Value) -> Guarantee<T>
    ) -> Guarantee<T> {
        let gurantee = Guarantee<T>()
        observe { result in
            if let queue = queue { gurantee.currentQueue = queue }
            switch result {
            case .success(let value):
                // Only perform an async dispatch if we're not
                // already on the correct queue.
                if let queue = queue, queue != self.currentQueue {
                    queue.async {
                        gurantee.resolve(on: queue, with: block(value))
                    }
                } else {
                    gurantee.resolve(on: queue, with: block(value))
                }
            case .failure(let error):
                owsFail("Unexpectedly received error result from unfailable promise \(error)")
            }
        }
        return gurantee
    }

    func observe<T>(
        on queue: DispatchQueue?,
        block: @escaping (Value) throws -> Promise<T>
    ) -> Promise<T> {
        let promise = Promise<T>()
        observe { result in
            if let queue = queue { promise.currentQueue = queue }

            func resultHandler() {
                do {
                    switch result {
                    case .success(let value):
                        promise.resolve(on: queue, with: try block(value))
                    case .failure(let error):
                        promise.reject(error)
                    }
                } catch {
                    promise.reject(error)
                }
            }

            // Only perform an async dispatch if we're not
            // already on the correct queue.
            if let queue = queue, queue != self.currentQueue {
                queue.async { resultHandler() }
            } else {
                resultHandler()
            }
        }

        return promise
    }
}
