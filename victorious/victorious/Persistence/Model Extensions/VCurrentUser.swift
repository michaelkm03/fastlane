//
//  VUser+Current.swift
//  victorious
//
//  Created by Patrick Lynch on 11/11/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import CoreData

let kLastLoginTypeUserDefaultsKey = "com.getvictorious.VUserManager.LoginType"
let kAccountIdentifierDefaultsKey = "com.getvictorious.VUserManager.AccountIdentifier"

let kManagedObjectContextUserInfoCurrentUserKey = "com.victorious.Persstence.CurrentUser"

public class VCurrentUser: NSObject {
    
    static var persistentStore: PersistentStoreType = PersistentStoreSelector.mainPersistentStore
    
    /// Returns a `VUser` object from the provided managed object context's user info dictionary
    /// (for performance and conveninece reasons).  This method is thread safe, and will handle loading
    /// the user from the proper context depending on which thread it is invoked.
    static func user( inManagedObjectContext managedObjectContext: NSManagedObjectContext ) -> VUser? {
        
        let user: VUser? = persistentStore.mainContext.v_performBlockAndWait() { context in
            context.userInfo[ kManagedObjectContextUserInfoCurrentUserKey ] as? VUser
        }
        guard let userFromMainContext = user else {
            return nil
        }
        
        if managedObjectContext == persistentStore.mainContext {
            print( "CurrentUser :: remoteID \(userFromMainContext.remoteId) :: token \(userFromMainContext.token)" )
            return userFromMainContext
            
        } else {
            let objectID = userFromMainContext.objectID
            return managedObjectContext.v_performBlockAndWait { context in
                if let currentUser = context.objectWithID( objectID ) as? VUser {
                    print( "CurrentUser (BG) :: remoteID \(currentUser.remoteId) :: token \(currentUser.token)" )
                }
                return context.objectWithID( objectID ) as? VUser
            }
        }
    }

    static func user() -> VUser? {
        return VCurrentUser.user( inManagedObjectContext: persistentStore.mainContext )
    }
    
    /// Strips the current user of its "current" status.  `currentUser()` method will
    /// now return nil until a new user has been set as current using method `setAsCurrent()`.
    static func clear() {
        persistentStore.mainContext.v_performBlockAndWait() { context in
            context.userInfo[ kManagedObjectContextUserInfoCurrentUserKey ] = nil
        }
    }
}

public extension VUser {
    
    /// Sets the receiver as the current user returned in `currentUser()` method.  Any previous
    /// current user will lose its current status, as their can be only one.
    func setAsCurrentUser() {
        VCurrentUser.persistentStore.mainContext.v_performBlockAndWait() { context in
            context.userInfo[ kManagedObjectContextUserInfoCurrentUserKey ] = self
        }
    }
    
    func isCurrentUser() -> Bool {
        return self.isEqualToUser( VCurrentUser.user() )
    }
}
