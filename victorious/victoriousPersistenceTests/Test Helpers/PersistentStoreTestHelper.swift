//
//  PersistentStoreTestHelper.swift
//  victorious
//
//  Created by Alex Tamoykin on 1/2/16.
//  Copyright © 2016 Victorious. All rights reserved.

import XCTest
@testable import victorious

/// Helper for testing a RequestOperation or it's subclass.
struct PersistentStoreTestHelper {

    let persistentStore: TestPersistentStore

    func createUser(remoteId remoteId: Int, token: String = "token") -> VUser {
        return persistentStore.mainContext.v_createObjectAndSave { user in
            user.remoteId = remoteId
            user.status = "stored"
            user.token = token
        } as VUser
    }

    func createSequence(remoteId remoteId: Int) -> VSequence {
        return persistentStore.mainContext.v_createObjectAndSave { sequence in
            sequence.remoteId = String(remoteId)
            sequence.commentCount = 1
            sequence.createdBy = 1
            sequence.gifCount = 1
            sequence.hasBeenRepostedByMainUser = true
            sequence.hasReposted = true
            sequence.isComplete = true
            sequence.isLikedByMainUser = true
            sequence.isComplete = true
            sequence.isGifStyle = true
            sequence.isRemix = true
            sequence.isRepost = true
            sequence.likeCount = 1
            sequence.memeCount = 1
            sequence.nameEmbeddedInContent = true
            sequence.permissionsMask = 1
            sequence.repostCount = 1
        } as VSequence
    }

    func createAdBreak(adSystemID adSystemID: UInt = kMonetizationPartnerIMA,
        adTag: String = "http://example.com") -> VAdBreak {
            return persistentStore.mainContext.v_createObjectAndSave { adBreak in
                adBreak.adSystemID = adSystemID
                adBreak.adTag = adTag
            } as VAdBreak
    }

    func createConversation() -> VConversation {
        let conversation: VConversation = persistentStore.mainContext.v_createObject()
        conversation.displayOrder = 0
        conversation.remoteId = 0
        conversation.lastMessageText = ""
        conversation.isRead = false
        conversation.postedAt = NSDate()
        conversation.messages = NSOrderedSet()
        return conversation
    }
}