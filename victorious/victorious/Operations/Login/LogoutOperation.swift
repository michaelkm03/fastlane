//
//  LogoutOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 11/11/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import FBSDKLoginKit
import Foundation
import VictoriousIOSSDK

class LogoutOperation: AsyncOperation<Void> {
    
    // MARK: - Initializing
    
    init(dependencyManager: VDependencyManager? = nil) {
        self.dependencyManager = dependencyManager
        super.init()
        qualityOfService = .UserInitiated
    }
    
    // MARK: - Initializing
    
    private let dependencyManager: VDependencyManager?
    
    override var executionQueue: Queue {
        return .background
    }
    
    override func execute(finish: (result: OperationResult<Void>) -> Void) {
        guard VCurrentUser.user != nil else {
            // Cannot logout without a current (logged-in) user
            finish(result: .failure(NSError(domain: "LogoutOperation", code: -1, userInfo: [:])))
            return
        }
        
        RequestOperation(request: LogoutRequest()).queue { [weak self] result in
            InterstitialManager.sharedInstance.clearAllRegisteredAlerts()
            
            NSUserDefaults.standardUserDefaults().removeObjectForKey(kLastLoginTypeUserDefaultsKey)
            NSUserDefaults.standardUserDefaults().removeObjectForKey(kAccountIdentifierDefaultsKey)
            
            VStoredLogin().clearLoggedInUserFromDisk()
            VStoredPassword().clearSavedPassword()
            FBSDKLoginManager().logOut()
            
            VTrackingManager.sharedInstance().trackEvent(VTrackingEventUserDidLogOut)
            
            // Try to reset the network resource token.
            self?.dependencyManager?.forumNetworkSource?.tearDown()
            
            // And finally, clear the user.  Don't do this early because
            // some of the stuff above requires knowing the current user
            VCurrentUser.clear()
        }
    }
}