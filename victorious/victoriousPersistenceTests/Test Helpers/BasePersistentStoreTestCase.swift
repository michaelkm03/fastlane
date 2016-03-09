//
//  BasePersistentStoreTestCase.swift
//  victorious
//
//  Created by Alex Tamoykin on 1/24/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import XCTest
@testable import victorious

/// Provides plumbing for testing iteractions with a persistent store.
class BasePersistentStoreTestCase: XCTestCase {
    
    let expectationThreshold: Double = 1
    var persistentStoreHelper: PersistentStoreTestHelper!
    var testStore: TestPersistentStore!

    override func setUp() {
        super.setUp()
        testStore = TestPersistentStore()
        testStore.deletePersistentStore()
        persistentStoreHelper = PersistentStoreTestHelper(persistentStore: testStore)
    }
}
