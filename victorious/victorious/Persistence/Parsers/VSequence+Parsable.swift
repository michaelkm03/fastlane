//
//  VSequence+PersistenceParsable.swift
//  victorious
//
//  Created by Patrick Lynch on 11/5/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

extension VSequence: PersistenceParsable {
    
    func populate( fromSourceModel streamItem: StreamItemType ) {
        guard let sequence = streamItem as? Sequence else {
            return
        }
        remoteId                = sequence.sequenceID
        category                = sequence.category.rawValue
        
        isGifStyle              = sequence.isGifStyle ?? isGifStyle
        commentCount            = sequence.commentCount ?? commentCount
        gifCount                = sequence.gifCount ?? gifCount
        hasReposted             = sequence.hasReposted ?? hasReposted
        isComplete              = sequence.isComplete ?? isComplete
        isRemix                 = sequence.isRemix ?? isRemix
        isRepost                = sequence.isRepost ?? isRepost
        likeCount               = sequence.likeCount ?? likeCount
        memeCount               = sequence.memeCount ?? memeCount
        name                    = sequence.name ?? name
        nameEmbeddedInContent   = sequence.nameEmbeddedInContent ?? nameEmbeddedInContent
        permissionsMask         = sequence.permissionsMask ?? permissionsMask
        repostCount             = sequence.repostCount ?? repostCount
        sequenceDescription     = sequence.sequenceDescription ?? sequenceDescription
        releasedAt              = sequence.releasedAt ?? releasedAt
        trendingTopicName       = sequence.trendingTopicName ?? trendingTopicName
        isLikedByMainUser       = sequence.isLikedByMainUser ?? isLikedByMainUser
        headline                = sequence.headline ?? headline
        previewData             = sequence.previewData ?? previewData
        previewType             = sequence.previewType?.rawValue
        previewImagesObject     = sequence.previewImagesObject ?? previewImagesObject
        itemType                = sequence.type?.rawValue
        itemSubType             = sequence.subtype?.rawValue
        releasedAt              = sequence.releasedAt ?? releasedAt
        
        if let trackingModel = sequence.tracking {
            tracking = v_managedObjectContext.v_createObject() as VTracking
            tracking?.populate(fromSourceModel: trackingModel)
        }

        if let adBreak = sequence.adBreak {
            let persistentAdBreak = v_managedObjectContext.v_createObject() as VAdBreak
            persistentAdBreak.populate(fromSourceModel: adBreak)
            self.adBreak = persistentAdBreak
        }

        self.user = v_managedObjectContext.v_findOrCreateObject( [ "remoteId" : sequence.user.userID ] ) as VUser
        self.user.populate(fromSourceModel: sequence.user)
        
        if let parentUser = sequence.parentUser {
            self.parentUserId = NSNumber(integer: parentUser.userID)
            let persistentParentUser = v_managedObjectContext.v_findOrCreateObject([ "remoteId" : parentUser.userID ]) as VUser
            persistentParentUser.populate(fromSourceModel: parentUser)
            self.parentUser = persistentParentUser
        }
        
        if let previewImageAssets = sequence.previewImageAssets where !previewImageAssets.isEmpty {
            self.previewImageAssets = Set<VImageAsset>(previewImageAssets.flatMap {
                let imageAsset: VImageAsset = self.v_managedObjectContext.v_findOrCreateObject([ "imageURL" : $0.url.absoluteString ])
                imageAsset.populate( fromSourceModel: $0 )
                return imageAsset
            })
        }
        
        if let textPostAsset = sequence.previewTextPostAsset {
            let persistentAsset: VAsset = v_managedObjectContext.v_createObject()
            persistentAsset.populate(fromSourceModel: textPostAsset)
            previewTextPostAsset = persistentAsset
        }
        
        if let nodes = sequence.nodes where !nodes.isEmpty {
            self.nodes = NSOrderedSet(array: nodes.flatMap {
                let node: VNode = v_managedObjectContext.v_createObject()
                node.populate( fromSourceModel: $0 )
                node.sequence = self
                return node
            })
        }
        
        if let voteResults = sequence.voteTypes where !voteResults.isEmpty {
            self.voteResults = Set<VVoteResult>(voteResults.flatMap {
                guard let id = Int($0.voteID) else {
                    return nil
                }
                let uniqueElements: [String : AnyObject] = [
                    "sequence.remoteId" : remoteId,
                    "remoteId" : NSNumber(integer: id)
                ]
                
                let persistentVoteResult: VVoteResult = self.v_managedObjectContext.v_findOrCreateObject(uniqueElements)
                persistentVoteResult.sequence = self
                persistentVoteResult.count = $0.voteCount
                return persistentVoteResult
            })
        }
    }
}
