//
//  VPushNotificationManager.swift
//  victorious
//
//  Created by Jarod Long on 9/8/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

extension VPushNotificationManager {
    func queueRegisterPushNotificationOperationWithPushNotificationID(pushNotificationID: String, completion: (error: NSError?) -> Void) {
        RequestOperation(request: RegisterPushNotificationRequest(pushNotificationID: pushNotificationID)).queue { result in
            completion(error: result.error as? NSError)
        }
    }
}