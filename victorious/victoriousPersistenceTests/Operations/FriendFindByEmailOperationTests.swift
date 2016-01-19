//
//  FriendFindByEmailOperationTests.swift
//  victorious
//
//  Created by Michael Sena on 1/5/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import XCTest
@testable import victorious
@testable import VictoriousIOSSDK

class FriendFindByEmailOperationTests: BaseRequestOperationTestCase {
    let testUserID: Int = 1
    let emails = ["h@h.hh", "mike@msena.com"]
    
    func testResults() {
        guard let operation = FriendFindByEmailOperation(emails: emails) else {
            XCTFail("Operation initialization should not fail here")
            return
        }
        operation.persistentStore = testStore
        
        let expectation = expectationWithDescription("FriendFindByOnComplete")

        let user = User(userID: self.testUserID)
        operation.onComplete([user]) {
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(expectationThreshold) { error in
            guard let results = operation.results,
                let firstResult = results.first as? VUser else {
                XCTFail("We should have results here")
                return
            }
            XCTAssertEqual(firstResult.remoteId.integerValue, self.testUserID)
        }
    }

    func testInitializationFail() {
        let operation = FriendFindByEmailOperation(emails: [])
        XCTAssertNil(operation)
    }
}
