//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
public class AnyPromise: NSObject {
    private let promise = Promise<Any>()

    public required init<T>(_ promise: Promise<T>) {
        promise.done { value in
            promise.resolve(value)
        }.catch { error in
            promise.reject(error)
        }
    }

    public required override init() {
        super.init()
    }

    @objc
    public func map() -> ((@escaping (Any) -> Any) -> AnyPromise) {
        { AnyPromise(self.promise.map($0)) }
    }

    @objc
    public func mapOn() -> ((DispatchQueue, @escaping (Any) -> Any) -> AnyPromise) {
        { AnyPromise(self.promise.map(on: $0, $1)) }
    }

    @objc
    public func done() -> ((@escaping (Any) -> Void) -> AnyPromise) {
        { AnyPromise(self.promise.done($0)) }
    }

    @objc
    public func doneOn() -> ((DispatchQueue, @escaping (Any) -> Void) -> AnyPromise) {
        { AnyPromise(self.promise.done(on: $0, $1)) }
    }

    @objc
    public func then() -> ((@escaping (Any) -> AnyPromise) -> AnyPromise) {
        { block in
            AnyPromise(self.promise.then { block($0).promise })
        }
    }

    @objc
    public func thenOn() -> ((DispatchQueue, @escaping (Any) -> AnyPromise) -> AnyPromise) {
        { queue, block in
            AnyPromise(self.promise.then(on: queue) { block($0).promise })
        }
    }

    @objc
    public func `catch`() -> ((@escaping (Error) -> Void) -> AnyPromise) {
        { AnyPromise(self.promise.catch($0)) }
    }

    @objc
    public func catchOn() -> ((DispatchQueue, @escaping (Error) -> Void) -> AnyPromise) {
        { AnyPromise(self.promise.catch(on: $0, $1)) }
    }

    @objc
    public func ensure() -> ((@escaping () -> Void) -> AnyPromise) {
        { AnyPromise(self.promise.ensure($0)) }
    }

    @objc
    public func ensureOn() -> ((DispatchQueue, @escaping () -> Void) -> AnyPromise) {
        { AnyPromise(self.promise.ensure(on: $0, $1)) }
    }

    public func asVoid() -> Promise<Void> {
        promise.asVoid()
    }
}

extension AnyPromise: Thenable, Catchable {
    public typealias Value = Any

    public var currentQueue: DispatchQueue? {
        get {
            promise.currentQueue
        }
        set {
            promise.currentQueue = newValue
        }
    }

    public func observe(_ block: @escaping (AnyPromise.Result) -> Void) {
        promise.observe(block)
    }

    public func resolve(_ value: Any) {
        promise.resolve(value)
    }

    public func resolve<T>(on queue: DispatchQueue?, with thenable: T) where T : Thenable, Any == T.Value {
        promise.resolve(on: queue, with: thenable)
    }

    public func reject(_ error: Error) {
        promise.reject(error)
    }
}
