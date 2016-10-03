//
//  UserBlockToggleOperationTests.swift
//  victorious
//
//  Created by Vincent Ho on 6/15/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import XCTest
@testable import victorious

class UserBlockToggleOperationTests: XCTestCase {
    let remoteUserID = 12345
    let currentUserID = 54321
    
    override func setUp() {
        super.setUp()
        let user = User(id: currentUserID)
        VCurrentUser.update(to: user)
    }
    
    func testInitiallyBlocked() {
        let user = User(id: remoteUserID)
        user.block()
        
        let expectation = self.expectation(description: "UserBlockToggleOperation")
        
        let operation = UserBlockToggleOperation(
            user: user,
            blockAPIPath: APIPath(templatePath:"foo"),
            unblockAPIPath: APIPath(templatePath:"foo")
        )
        
        operation.queue { result in
            XCTAssertFalse(user.isBlocked)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testInitiallyUnblocked() {
        let user = User(id: remoteUserID)
        user.unblock()
        
        let expectation = self.expectation(description: "UserBlockToggleOperation")
        
        let operation = UserBlockToggleOperation(
            user: user,
            blockAPIPath: APIPath(templatePath:"foo"),
            unblockAPIPath: APIPath(templatePath:"foo")
        )
        
        operation.queue { result in
            XCTAssertTrue(user.isBlocked)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
