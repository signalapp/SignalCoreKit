//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public protocol Thenable: AnyObject {
    associatedtype Value
    var result: Result<Value, Error>? { get }
    init()
    func observe(on queue: DispatchQueue, block: @escaping (Result<Value, Error>) -> Void)
    func resolve(_ value: Value)
    func resolve<T: Thenable>(on queue: DispatchQueue, with thenable: T) where T.Value == Value
}

public extension Thenable {
    func map<T>(
        on queue: DispatchQueue = .main,
        _ block: @escaping (Value) throws -> T
    ) -> Promise<T> {
        observe(on: queue, block: block)
    }

    func done(
        on queue: DispatchQueue = .main,
        _ block: @escaping (Value) throws -> Void
    ) -> Promise<Void> {
        observe(on: queue, block: block)
    }

    func then<T: Thenable>(
        on queue: DispatchQueue = .main,
        _ block: @escaping (Value) throws -> T
    ) -> Promise<T.Value> {
        let promise = Promise<T.Value>()
        observe(on: queue) { result in
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

    var value: Value? {
        guard case .success(let value) = result else { return nil }
        return value
    }

    func asVoid() -> Promise<Void> { map { _ in } }
}

fileprivate extension Thenable {
    func observe<T>(
        on queue: DispatchQueue,
        block: @escaping (Value) throws -> T
    ) -> Promise<T> {
        let promise = Promise<T>()
        observe(on: queue) { result in
            do {
                switch result {
                case .success(let value):
                    promise.resolve(try block(value))
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

public extension Thenable where Value == Void {
    func resolve() { resolve(()) }
}
