//
//  ImageSearchRequestTests.swift
//  victorious
//
//  Created by Cody Kolodziejzyk on 11/10/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import SwiftyJSON
import VictoriousIOSSDK
import XCTest

class ImageSearchRequestTests: XCTestCase {
    
    func testResponseParsing() {
        guard let mockResponseDataURL = NSBundle(forClass: self.dynamicType).URLForResource("ImageSearchResponse", withExtension: "json"),
            let mockData = NSData(contentsOfURL: mockResponseDataURL) else {
                XCTFail("Error reading mock json data")
                return
        }
        
        do {
            let searchImages = ImageSearchRequest(searchTerm: "surfer")
            let (results, nextPage, previousPage) = try searchImages.parseResponse(NSURLResponse(), toRequest: searchImages.urlRequest, responseData: mockData, responseJSON: JSON(data: mockData))
            XCTAssertEqual(results.count, 35)
            XCTAssertEqual(results[0].imageURL, NSURL(string: "http://lithe.files.wordpress.com/2008/02/surfer.jpg")!)
            XCTAssertEqual(results[1].imageURL, NSURL(string: "http://www.myprosurfer.co.uk/wp-content/uploads/surfer-420x261.jpg")!)
            
            XCTAssertNil(previousPage, "There should be no page before page 1")
            XCTAssertNotNil(nextPage, "There should be a next page")
            
        } catch {
            XCTFail("Sorry, parseResponse should not throw here")
        }
    }
    
    func testRequest() {
        let searchImages = ImageSearchRequest(searchTerm: "surfer", pageNumber: 1, itemsPerPage: 100)
        XCTAssertEqual(searchImages.urlRequest.URL?.absoluteString, "/api/image/search/surfer/1/100")
    }
}