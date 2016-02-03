//
//  LogoutOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 11/11/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

class LogoutOperation: RequestOperation {
    
    let request = LogoutRequest()

    override init() {
        super.init()
        self.qualityOfService = .UserInitiated
    }
    
    override func main() {
        let currentUser: VUser? = dispatch_sync( dispatch_get_main_queue() ) {
            return VCurrentUser.user()
        }
        guard currentUser != nil else {
            // Cannot logout without a current (logged-in) user
            return
        }
        
        dispatch_sync( dispatch_get_main_queue() ) {
            
            InterstitialManager.sharedInstance.clearAllRegisteredAlerts()
            
            NSUserDefaults.standardUserDefaults().removeObjectForKey( kLastLoginTypeUserDefaultsKey )
            NSUserDefaults.standardUserDefaults().removeObjectForKey( kAccountIdentifierDefaultsKey )
            
            VStoredLogin().clearLoggedInUserFromDisk()
            VStoredPassword().clearSavedPassword()
            
            VTrackingManager.sharedInstance().trackEvent( VTrackingEventUserDidLogOut )
            VTrackingManager.sharedInstance().setValue(false, forSessionParameterWithKey:VTrackingKeyUserLoggedIn)
        }
        
        persistentStore.createBackgroundContext().v_performBlockAndWait() { context in
            context.v_deleteAllObjectsWithEntityName( VConversation.v_entityName() )
            context.v_deleteAllObjectsWithEntityName( VNotification.v_entityName() )
            context.v_deleteAllObjectsWithEntityName( VPollResult.v_entityName() )
            context.v_save()
        }
        
        // And finally, clear the user.  Don't do this early because
        // some of the stuff above requires knowing the current user
        VCurrentUser.clear()
        
        // Execute the network request and don't wait for response
        requestExecutor.executeRequest( request, onComplete: nil, onError: nil )
    }
}