//
//  CommentsDataSource.swift
//  victorious
//
//  Created by Michael Sena on 8/14/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

import Foundation

class CommentsDataSource : PaginatedDataSource, UICollectionViewDataSource {
    
    private let sequence: VSequence
    
    private let dependencyManager: VDependencyManager
    
    private var registeredCommentReuseIdentifiers = Set<String>()
    
    init(sequence: VSequence, dependencyManager: VDependencyManager) {
        self.sequence = sequence
        self.dependencyManager = dependencyManager
        super.init()
    }
    
    func loadComments( pageType: VPageType, completion:((NSError?)->())? = nil ) {
        self.loadPage( pageType,
            createOperation: {
                return SequenceCommentsOperation(sequenceID: self.sequence.remoteId)
            },
            completion: { (operation, error) in
                completion?(error)
            }
        )
    }
    
    func deleteSequence( completion completion: ((NSError?)->())? = nil ) {
        DeleteSequenceOperation(sequenceID: self.sequence.remoteId).queue() { error in
            completion?( error )
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleItems.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let comment = visibleItems[indexPath.item] as! VComment
        let reuseIdentifierForComment = MediaAttachmentView.reuseIdentifierForComment(comment)
        if !registeredCommentReuseIdentifiers.contains(reuseIdentifierForComment) {
            collectionView.registerNib(VContentCommentsCell.nibForCell(), forCellWithReuseIdentifier: reuseIdentifierForComment)
            registeredCommentReuseIdentifiers.insert(reuseIdentifierForComment)
        }
        return collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifierForComment, forIndexPath: indexPath)
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        return collectionView.dequeueReusableSupplementaryViewOfKind( UICollectionElementKindSectionFooter, withReuseIdentifier: "MediaSearchActivityFooter", forIndexPath: indexPath )
    }
}
