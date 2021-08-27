//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public protocol Thenable: AnyObject {
    associatedtype Value
    typealias Result = Swift.Result<Value, Error>
    init()
    var currentQueue: DispatchQueue? { get set }
    func observe(on queue: DispatchQueue?, block: @escaping (Result) -> Void)
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
        let guarantee = Guarantee<T>()
        observe(on: queue) { result in
            guarantee.currentQueue = .current
            switch result {
            case .success(let value):
                guarantee.resolve(block(value))
            case .failure(let error):
                owsFail("Unexpectedly received error result from unfailable promise \(error)")
            }
        }
        return guarantee
    }

    func observe<T>(
        on queue: DispatchQueue?,
        block: @escaping (Value) -> Guarantee<T>
    ) -> Guarantee<T> {
        let guarantee = Guarantee<T>()
        observe(on: queue) { result in
            guarantee.currentQueue = .current
            switch result {
            case .success(let value):
                guarantee.resolve(on: .current, with: block(value))
            case .failure(let error):
                owsFail("Unexpectedly received error result from unfailable promise \(error)")
            }
        }
        return guarantee
    }

    func observe<T>(
        on queue: DispatchQueue?,
        block: @escaping (Value) throws -> Promise<T>
    ) -> Promise<T> {
        let promise = Promise<T>()
        observe(on: queue) { result in
            promise.currentQueue = .current
            do {
                switch result {
                case .success(let value):
                    promise.resolve(on: .current, with: try block(value))
                case .failure(let error):
                    promise.reject(error)
                }
            } catch {
                promise.reject(error)
            }
        }

        return promise
    }
}

public extension DispatchQueue {
    class var current: DispatchQueue { DispatchCurrentQueue() }
    func asyncIfNecessary(
        execute work: @escaping @convention(block) () -> Void
    ) {
        if self == Self.current {
            work()
        } else {
            async { work() }
        }
    }
}

public extension Optional where Wrapped == DispatchQueue {
    func asyncIfNecessary(
        execute work: @escaping @convention(block) () -> Void
    ) {
        switch self {
        case .some(let queue):
            queue.asyncIfNecessary(execute: work)
        case .none:
            work()
        }
    }
}
