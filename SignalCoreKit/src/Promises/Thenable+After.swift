//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public extension Guarantee where Value == Void {
    static func after(seconds: TimeInterval) -> Guarantee<Void> {
        let guarantee = Guarantee<Void>()
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds) {
            guarantee.resolve()
        }
        return guarantee
    }
}
