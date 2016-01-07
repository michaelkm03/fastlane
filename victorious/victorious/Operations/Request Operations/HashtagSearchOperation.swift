//
//  HashtagSearchOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 1/6/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

@objc class HashtagSearchResultObject: NSObject {
    let sourceResult: VictoriousIOSSDK.Hashtag
    
    init( hashtag: VictoriousIOSSDK.Hashtag ) {
        self.sourceResult = hashtag
    }
}

final class HashtagSearchOperation: RequestOperation, PaginatedOperation {
    
    private(set) var results: [AnyObject]?
    private(set) var didResetResults = false
    
    let request: HashtagSearchRequest
    private let escapedQueryString: String
    
    required init( request: HashtagSearchRequest ) {
        self.request = request
        self.escapedQueryString = request.queryString
    }
    
    convenience init?( queryString: String ) {
        guard let escapedString = queryString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.vsdk_pathPartCharacterSet()) else {
            return nil
        }
        self.init(request: HashtagSearchRequest(query: escapedString))
    }
    
    override func main() {
        requestExecutor.executeRequest(self.request, onComplete: self.onComplete, onError: self.onError)
    }
    
    private func onError( error: NSError, completion: ()->() ) {
        completion()
    }
    
    private func onComplete( networkResult: HashtagSearchRequest.ResultType, completion: () -> () ) {
        
        self.results = networkResult.map{ HashtagSearchResultObject(hashtag: $0) }
        
        // Call the completion block before the Core Data context saves because consumers only care about the networkHashtags
        completion()
        
        // Populate our local hashtags cache based off the new data
        persistentStore.backgroundContext.v_performBlock { context in
            guard !networkResult.isEmpty else {
                return
            }
            
            for networkHashtag in networkResult {
                let localHashtag: VHashtag = context.v_findOrCreateObject([ "tag" : networkHashtag.tag ])
                localHashtag.populate(fromSourceModel: networkHashtag)
            }
            
            context.v_save()
        }
    }
}
