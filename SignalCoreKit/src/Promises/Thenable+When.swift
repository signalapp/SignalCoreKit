//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public extension Thenable {
    static func when<T: Thenable>(fullfilled thenables: T...) -> Promise<Void> where T.Value == Value {
        when(fullfilled: thenables)
    }

    static func when<T: Thenable>(fullfilled thenables: [T]) -> Promise<Void> where T.Value == Value {
        guard !thenables.isEmpty else { return Promise(value: ()) }

        var pendingPromiseCount = thenables.count

        let returnPromise = Promise<Void>()

        let lock = UnfairLock()

        for thenable in thenables {
            thenable.observe { result in
                lock.withLock {
                    switch result {
                    case .success:
                        guard !returnPromise.future.isSealed else { return }
                        pendingPromiseCount -= 1
                        if pendingPromiseCount == 0 { returnPromise.resolve(()) }
                    case .failure(let error):
                        guard !returnPromise.future.isSealed else { return }
                        returnPromise.reject(error)
                    }
                }
            }
        }

        return returnPromise
    }

    static func when<T: Thenable>(resolved thenables: T...) -> Guarantee<Void> where T.Value == Value {
        when(resolved: thenables)
    }

    static func when<T: Thenable>(resolved thenables: [T]) -> Guarantee<Void> where T.Value == Value {
        guard !thenables.isEmpty else { return Guarantee(value: ()) }

        var pendingPromiseCount = thenables.count

        let returnGuarantee = Guarantee<Void>()

        let lock = UnfairLock()

        for thenable in thenables {
            thenable.observe { _ in
                lock.withLock {
                    pendingPromiseCount -= 1
                    if pendingPromiseCount == 0 { returnGuarantee.resolve(()) }
                }
            }
        }

        return returnGuarantee
    }
}
