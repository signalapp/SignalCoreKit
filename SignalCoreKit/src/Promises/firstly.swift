//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public func firstly<T: Thenable>(
    _ block: () throws -> T
) -> Promise<T.Value> {
    let promise = Promise<T.Value>()
    do {
        promise.resolve(on: .current, with: try block())
    } catch {
        promise.reject(error)
    }
    return promise
}

public func firstly<T: Thenable>(
    on queue: DispatchQueue,
    _ block: @escaping () throws -> T
) -> Promise<T.Value> {
    let promise = Promise<T.Value>()
    queue.asyncIfNecessary {
        do {
            promise.resolve(on: queue, with: try block())
        } catch {
            promise.reject(error)
        }
    }
    return promise
}

public func firstly<T>(
    on queue: DispatchQueue,
    _ block: @escaping () throws -> T
) -> Promise<T> {
    let promise = Promise<T>()
    queue.asyncIfNecessary {
        do {
            promise.resolve(try block())
        } catch {
            promise.reject(error)
        }
    }
    return promise
}

public func firstly<T>(
    on queue: DispatchQueue,
    _ block: @escaping () -> T
) -> Guarantee<T> {
    let guarantee = Guarantee<T>()
    queue.asyncIfNecessary {
        guarantee.resolve(block())
    }
    return guarantee
}
