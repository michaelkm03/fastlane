//
//  TestPersistentStore.swift
//  victorious
//
//  Created by Alex Tamoykin on 12/22/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation

/// A concrete implementation of `PersistentStoreType` to be used for unit tests and automation tests.
/// You may freely populate this persistent store with whatever data is required for a test as well
/// as delete any or all of its contents.
class TestPersistentStore: NSObject, PersistentStoreType {

    static let persistentStorePath = "victoriOS-test.sqlite"
    static let managedObjectModelName = "victoriOS"
    static let managedObjectModelVersion = MainPersistentStore.managedObjectModelVersion
        
    private static var coreDataManageInstancer: CoreDataManager?
    
    var sharedCoreDataManager: CoreDataManager {
        if let coreDataManageInstancer = TestPersistentStore.coreDataManageInstancer {
            return coreDataManageInstancer
        }
        
        let docsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let persistentStoreURL = docsDirectory.URLByAppendingPathComponent( TestPersistentStore.persistentStorePath )
        
        let momPath = ("\(TestPersistentStore.managedObjectModelName).momd" as NSString).stringByAppendingPathComponent( TestPersistentStore.managedObjectModelVersion )
        guard let momURLInBundle = NSBundle.mainBundle().URLForResource( momPath, withExtension: "mom" ) else {
            fatalError( "Cannot find managed object model (.mom) for URL in bundle: \(momPath)" )
        }
        
        let newCoreDataManageInstancer = CoreDataManager(
            persistentStoreURL: persistentStoreURL,
            currentModelVersion: CoreDataManager.ModelVersion(
                identifier: TestPersistentStore.managedObjectModelVersion,
                managedObjectModelURL: momURLInBundle
            ),
            previousModelVersion: nil
        )
        TestPersistentStore.coreDataManageInstancer = newCoreDataManageInstancer
        return newCoreDataManageInstancer
    }
    
    var mainContext: NSManagedObjectContext {
        return sharedCoreDataManager.mainContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return sharedCoreDataManager.backgroundContext
    }
    
    func deletePersistentStore() throws {
        guard let coreDataMgr = TestPersistentStore.coreDataManageInstancer else {
            return
        }
        let url = coreDataMgr.persistentStoreURL
        do {
            try NSFileManager.defaultManager().removeItemAtURL( url )
             TestPersistentStore.coreDataManageInstancer = nil
        } catch {
            throw PersistentStoreError.DeleteFailed(storeURL: url, error: error)
        }
    }
}
