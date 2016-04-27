//
//  CreatorListOperation.swift
//  victorious
//
//  Created by Tian Lan on 4/25/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation

/// Performs a local fetch from persistent store for a list of creators
/// `self.results` are of type `[VUser]`
final class CreatorListOperation: FetcherOperation {
    
    required init(expandableURLString: String? = nil) {
        super.init()
        
        if let url = expandableURLString where !localFetch {
            let appID = VEnvironmentManager.sharedInstance().currentEnvironment.appID.integerValue
            CreatorListRemoteOperation(expandableURLString: url, appID: appID)?.before(self).queue()
        }
    }
    
    override func main() {
        return persistentStore.mainContext.v_performBlockAndWait {context in
            let fetchRequest = NSFetchRequest(entityName: VUser.v_entityName())
            let predicate = NSPredicate(format: "isCreator == true")
            fetchRequest.predicate = predicate
            self.results = context.v_executeFetchRequest(fetchRequest) as [VUser]
        }
    }
}