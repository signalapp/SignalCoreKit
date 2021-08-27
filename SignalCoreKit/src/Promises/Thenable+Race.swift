//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public extension Thenable {
    static func race<T: Thenable>(_ thenables: T...) -> Promise<T.Value> where T.Value == Value {
        race(thenables)
    }

    static func race<T: Thenable>(_ thenables: [T]) -> Promise<T.Value> where T.Value == Value {
        let returnPromise = Promise<T.Value>()

        for thenable in thenables {
            thenable.observe(on: .current) { result in
                switch result {
                case .success(let result):
                    guard !returnPromise.future.isSealed else { return }
                    returnPromise.resolve(result)
                case .failure(let error):
                    guard !returnPromise.future.isSealed else { return }
                    returnPromise.reject(error)
                }
            }
        }

        return returnPromise
    }
}
