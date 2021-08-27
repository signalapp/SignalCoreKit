//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public protocol Catchable: Thenable {
    func reject(_ error: Error)
}

public extension Catchable {
    @discardableResult
    func `catch`(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Error) throws -> Void
    ) -> Promise<Void> {
        observe(on: queue) { _ in
            ()
        } failureBlock: { error in
            try block(error)
        }
    }

    @discardableResult
    func recover(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Error) -> Value
    ) -> Guarantee<Value> {
        observe(on: queue, successBlock: { $0 }, failureBlock: block)
    }

    @discardableResult
    func recover(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Error) -> Guarantee<Value>
    ) -> Guarantee<Value> {
        observe(on: queue, successBlock: { $0 }, failureBlock: block)
    }

    func recover(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Error) throws -> Value
    ) -> Promise<Value> {
        observe(on: queue, successBlock: { $0 }, failureBlock: block)
    }

    func recover(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Error) throws -> Promise<Value>
    ) -> Promise<Value> {
        observe(on: queue, successBlock: { $0 }, failureBlock: block)
    }

    func ensure(
        on queue: DispatchQueue? = nil,
        _ block: @escaping () -> Void
    ) -> Promise<Value> {
        observe(on: queue) { value in
            block()
            return value
        } failureBlock: { _ in
            block()
        }
    }

    @discardableResult
    func cauterize() -> Self { self }

    func asVoid() -> Promise<Void> { map { _ in } }
}

public extension Thenable where Self: Catchable {
    func map<T>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) throws -> T
    ) -> Promise<T> {
        observe(on: queue, successBlock: block)
    }

    func map<T>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) -> T
    ) -> Promise<T> {
        observe(on: queue, successBlock: block)
    }

    func done(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) throws -> Void
    ) -> Promise<Void> {
        observe(on: queue, successBlock: block)
    }

    func done(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) -> Void
    ) -> Promise<Void> {
        observe(on: queue, successBlock: block)
    }

    func then<T: Thenable>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) throws -> T
    ) -> Self where T.Value == Value {
        observe(on: queue, successBlock: block)
    }

    func then<T: Thenable>(
        on queue: DispatchQueue? = nil,
        _ block: @escaping (Value) -> T
    ) -> Self where T.Value == Value {
        observe(on: queue, successBlock: block)
    }
}

fileprivate extension Thenable where Self: Catchable {
    func observe<T>(
        on queue: DispatchQueue?,
        successBlock: @escaping (Value) throws -> T,
        failureBlock: @escaping (Error) throws -> Void = { _ in }
    ) -> Promise<T> {
        let promise = Promise<T>()
        observe(on: queue) { result in
            promise.currentQueue = .current
            do {
                switch result {
                case .success(let value):
                    promise.resolve(try successBlock(value))
                case .failure(let error):
                    try failureBlock(error)
                    promise.reject(error)
                }
            } catch {
                promise.reject(error)
            }
        }
        return promise
    }

    func observe(
        on queue: DispatchQueue?,
        successBlock: @escaping (Value) -> Value,
        failureBlock: @escaping (Error) -> Value
    ) -> Guarantee<Value> {
        let guarantee = Guarantee<Value>()
        observe(on: queue) { result in
            guarantee.currentQueue = .current
            switch result {
            case .success(let value):
                guarantee.resolve(successBlock(value))
            case .failure(let error):
                guarantee.resolve(failureBlock(error))
            }
        }
        return guarantee
    }

    func observe(
        on queue: DispatchQueue?,
        successBlock: @escaping (Value) -> Value,
        failureBlock: @escaping (Error) -> Guarantee<Value>
    ) -> Guarantee<Value> {
        let guarantee = Guarantee<Value>()
        observe(on: queue) { result in
            guarantee.currentQueue = .current
            switch result {
            case .success(let value):
                guarantee.resolve(successBlock(value))
            case .failure(let error):
                guarantee.resolve(on: .current, with: failureBlock(error))
            }
        }
        return guarantee
    }

    func observe(
        on queue: DispatchQueue?,
        successBlock: @escaping (Value) throws -> Value,
        failureBlock: @escaping (Error) throws -> Value
    ) -> Promise<Value> {
        let promise = Promise<Value>()
        observe(on: queue) { result in
            promise.currentQueue = .current
            do {
                switch result {
                case .success(let value):
                    promise.resolve(try successBlock(value))
                case .failure(let error):
                    promise.resolve(try failureBlock(error))
                }
            } catch {
                promise.reject(error)
            }
        }
        return promise
    }

    func observe(
        on queue: DispatchQueue?,
        successBlock: @escaping (Value) throws -> Value,
        failureBlock: @escaping (Error) throws -> Promise<Value>
    ) -> Promise<Value> {
        let promise = Promise<Value>()
        observe(on: queue) { result in
            promise.currentQueue = .current
            do {
                switch result {
                case .success(let value):
                    promise.resolve(try successBlock(value))
                case .failure(let error):
                    promise.resolve(on: .current, with: try failureBlock(error))
                }
            } catch {
                promise.reject(error)
            }
        }
        return promise
    }

    func observe<T: Thenable>(
        on queue: DispatchQueue?,
        successBlock: @escaping (Value) throws -> T,
        failureBlock: @escaping (Error) throws -> Void = { _ in }
    ) -> Self where T.Value == Value {
        let thenable = Self.init()
        observe(on: queue) { result in
            thenable.currentQueue = .current
            do {
                switch result {
                case .success(let value):
                    thenable.resolve(on: .current, with: try successBlock(value))
                case .failure(let error):
                    try failureBlock(error)
                    thenable.reject(error)
                }
            } catch {
                thenable.reject(error)
            }
        }
        return thenable
    }
}
