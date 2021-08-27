//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
public class AnyPromise: NSObject {
    private let anyPromise = Promise<Any>()

    public convenience init<T: Thenable>(_ thenable: T) {
        self.init()

        if let promise = thenable as? Promise<T.Value> {
            promise.done { value in
                self.anyPromise.resolve(value)
            }.catch { error in
                self.anyPromise.reject(error)
            }
        } else {
            thenable.done { self.anyPromise.resolve($0) }
        }
    }

    @objc
    public class var withFutureOnCurrent: ((DispatchQueue, @escaping (AnyFuture) -> Void) -> AnyPromise) {
        { queue, block in
            let promise = AnyPromise()
            promise.anyPromise.currentQueue = queue
            block(AnyFuture(promise.anyPromise.future))
            return promise
        }
    }

    @objc
    public class var withFutureOn: ((DispatchQueue, @escaping (AnyFuture) -> Void) -> AnyPromise) {
        { queue, block in
            let promise = AnyPromise()
            promise.anyPromise.currentQueue = queue
            queue.async {
                block(AnyFuture(promise.anyPromise.future))
            }
            return promise
        }
    }

    @objc
    public convenience init(future: (AnyFuture) -> Void) {
        self.init()
        future(AnyFuture(anyPromise.future))
    }

    public required override init() {
        super.init()
    }

    @objc
    public var map: ((@escaping (Any) -> Any) -> AnyPromise) {
        { AnyPromise(self.anyPromise.map($0)) }
    }

    @objc
    public var mapOn: ((DispatchQueue, @escaping (Any) -> Any) -> AnyPromise) {
        { AnyPromise(self.anyPromise.map(on: $0, $1)) }
    }

    @objc
    public var done: ((@escaping (Any) -> Void) -> AnyPromise) {
        { AnyPromise(self.anyPromise.done($0)) }
    }

    @objc
    public var doneOn: ((DispatchQueue, @escaping (Any) -> Void) -> AnyPromise) {
        { AnyPromise(self.anyPromise.done(on: $0, $1)) }
    }

    @objc
    public var then: ((@escaping (Any) -> AnyPromise) -> AnyPromise) {
        { block in
            AnyPromise(self.anyPromise.then { block($0).anyPromise })
        }
    }

    @objc
    public var thenOn: ((DispatchQueue, @escaping (Any) -> AnyPromise) -> AnyPromise) {
        { queue, block in
            AnyPromise(self.anyPromise.then(on: queue) { block($0).anyPromise })
        }
    }

    @objc
    public var `catch`: ((@escaping (Error) -> Void) -> AnyPromise) {
        { AnyPromise(self.anyPromise.catch($0)) }
    }

    @objc
    public var catchOn: ((DispatchQueue, @escaping (Error) -> Void) -> AnyPromise) {
        { AnyPromise(self.anyPromise.catch(on: $0, $1)) }
    }

    @objc
    public var ensure: ((@escaping () -> Void) -> AnyPromise) {
        { AnyPromise(self.anyPromise.ensure($0)) }
    }

    @objc
    public var ensureOn: ((DispatchQueue, @escaping () -> Void) -> AnyPromise) {
        { AnyPromise(self.anyPromise.ensure(on: $0, $1)) }
    }

    public func asVoid() -> Promise<Void> {
        anyPromise.asVoid()
    }
}

extension AnyPromise: Thenable, Catchable {
    public typealias Value = Any

    public var currentQueue: DispatchQueue? {
        get {
            anyPromise.currentQueue
        }
        set {
            anyPromise.currentQueue = newValue
        }
    }

    public func observe(_ block: @escaping (AnyPromise.Result) -> Void) {
        anyPromise.observe(block)
    }

    public func resolve(_ value: Any) {
        anyPromise.resolve(value)
    }

    public func resolve<T>(on queue: DispatchQueue?, with thenable: T) where T: Thenable, Any == T.Value {
        anyPromise.resolve(on: queue, with: thenable)
    }

    public func reject(_ error: Error) {
        anyPromise.reject(error)
    }
}

@objc
public class AnyFuture: NSObject {
    private let future: Future<Any>
    required init(_ future: Future<Any>) {
        self.future = future
        super.init()
    }

    @objc
    public func resolve(value: Any) { future.resolve(value) }

    @objc
    public func reject(error: Error) { future.reject(error) }

    @objc
    public func resolveWithPromise(_ promise: AnyPromise) {
        future.resolve(with: promise)
    }

    @objc
    public func resolve(onQueue queue: DispatchQueue, withPromise promise: AnyPromise) {
        future.resolve(on: queue, with: promise)
    }
}
