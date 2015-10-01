//
//  HashtagShelf.swift
//  victorious
//
//  Created by Sharif Ahmed on 8/12/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

import Foundation
import CoreData

class HashtagShelf: Shelf {

    @NSManaged var hashtagTitle: String
    @NSManaged var amFollowing: NSNumber
    @NSManaged var postsCount: NSNumber

}
