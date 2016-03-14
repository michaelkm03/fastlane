//
//  TrendingHashtagOperation.swift
//  victorious
//
//  Created by Tian Lan on 1/18/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

class TrendingHashtagOperation: RemoteFetcherOperation, RequestOperation {
    
    let request: TrendingHashtagRequest! = TrendingHashtagRequest()
    
    override func main() {
        requestExecutor.executeRequest(request, onComplete: onComplete, onError: nil)
    }

    func onComplete( networkResult: TrendingHashtagRequest.ResultType ) {
        self.results = networkResult.map{ HashtagSearchResultObject(hashtag: $0) }
        
        // Queue a follow-up operation that parses to persistent store
        HashtagSaveOperation(hashtags: networkResult).after(self).queue()
    }
}