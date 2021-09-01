//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

public extension NotificationCenter {
    func observe(once name: Notification.Name, object: Any? = nil) -> Guarantee<Notification> {
        let guarantee = Guarantee<Notification>()
        let observer = addObserver(forName: name, object: object, queue: nil) { notification in
            guarantee.resolve(notification)
        }
        guarantee.done { _ in self.removeObserver(observer) }
        return guarantee
    }
}
