//
//  VContentTests.swift
//  victorious
//
//  Created by Vincent Ho on 5/18/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import XCTest
@testable import VictoriousIOSSDK
@testable import victorious

class VContentTests: BasePersistentStoreTestCase {    
    func testValid() {
        guard let content: VContent = createContentFromJSON(fileName: "ViewedContent") else {
            XCTFail("Failed to create a VContent")
            return
        }
        
        XCTAssertNotNil(content.v_author, "Author should not be nil")

        XCTAssertEqual(content.v_remoteID, "31415926535")
        XCTAssertEqual(content.v_status, "public")
        XCTAssertEqual(content.text, "We the People of the United States, in Order to form a more perfect Union, establish Justice, insure domestic Tranquility, provide for the common defence, promote the general Welfare, and secure the Blessings of Liberty to ourselves and our Posterity, do ordain and establish this Constitution for the United States of America.")
        XCTAssertEqual(content.shareURL?.absoluteString, "test_share_url")
        XCTAssertEqual(Int(content.releasedAt.timeIntervalSince1970), 123456/1000)
        XCTAssertEqual(content.v_contentPreviewAssets?.count, 4)
        XCTAssertEqual(content.v_contentMediaAssets?.count, 1)
        XCTAssertEqual(content.type, ContentType.video)
    }

    private func createContentFromJSON(fileName fileName: String) -> VContent? {
        guard let mockUserDataURL = NSBundle(forClass: self.dynamicType).URLForResource(fileName, withExtension: "json"),
            let mockData = NSData(contentsOfURL: mockUserDataURL) else {
                XCTFail("Error reading mock json data")
                return nil
        }
        
        guard let content = Content(json: JSON(data: mockData)) else {
            XCTFail("Error reading mock json data")
            return nil
        }
        let persistentSequenceModel: VContent = persistentStoreHelper.createContent("1")
        persistentSequenceModel.populate(fromSourceModel: content)
        return persistentSequenceModel
    }

}
