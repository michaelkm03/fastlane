//
//  HashtagSearchDataSource.swift
//  victorious
//
//  Created by Patrick Lynch on 1/6/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

final class HashtagSearchDataSource: PaginatedDataSource, SearchDataSourceType, UITableViewDataSource {
    
    private(set) var searchTerm: String?
    
    let dependencyManager: VDependencyManager
    
    weak var tableView: UITableView?
    
    required init(dependencyManager: VDependencyManager) {
        self.dependencyManager = dependencyManager
        super.init()
        
        if let currentUser = VCurrentUser.user() {
            self.KVOController.observe(currentUser,
                keyPath: "followedHashtags",
                options: [.New, .Old],
                action: Selector( "onFollowedChanged:" )
            )
        }
    }

    func onFollowedChanged( change: [NSObject: AnyObject]! ) {
        guard let objectChanged = ((change?[ NSKeyValueChangeNewKey ] ?? change?[ NSKeyValueChangeOldKey ]) as? NSArray)?.firstObject,
            let hashtag = (objectChanged as? VFollowedHashtag)?.hashtag else {
                return
        }
        
        let index = visibleItems.indexOfObjectPassingTest() { (obj, idx, stop) in
            return (obj as? HashtagSearchResultObject)?.tag == hashtag.tag
        }
        if index != NSNotFound,
            let cell = self.tableView?.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? VHashtagCell {
                self.updateFollowControlState(cell.followControl, forHashtag: hashtag.tag, animated: true)
        }
    }
    
    func registerCells( forTableView tableView: UITableView ) {
        let identifier = VHashtagCell.suggestedReuseIdentifier()
        let nib = UINib(nibName: identifier, bundle: NSBundle(forClass: VHashtagCell.self) )
        tableView.registerNib(nib, forCellReuseIdentifier: identifier)
        
        // Catch this table view and keep a weak reference for later
        self.tableView = tableView
    }
    
    //MARK: - API
    
    func search(searchTerm searchTerm: String, pageType: VPageType, completion:((NSError?)->())? = nil ) {
        
        self.searchTerm = searchTerm
        guard let operation = HashtagSearchOperation(searchTerm: searchTerm) else {
            return
        }
        
        loadPage( pageType,
            createOperation: {
                return operation
            },
            completion: { (operation, error) in
                completion?( error )
            }
        )
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.visibleItems.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = VHashtagCell.suggestedReuseIdentifier()
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! VHashtagCell
        let hashtagResult = visibleItems[indexPath.row] as! HashtagSearchResultObject
        cell.dependencyManager = self.dependencyManager
        let hashtag = hashtagResult.sourceResult.tag
        cell.hashtagText = hashtag
        self.updateFollowControlState(cell.followControl, forHashtag: hashtag, animated: false)
        cell.followControl?.onToggleFollow = {
            guard let currentUser = VCurrentUser.user() else {
                return
            }
            
            let operation: RequestOperation
            if currentUser.isFollowingHashtagString(hashtag) {
                operation = UnfollowHashtagOperation( hashtag: hashtag )
            } else {
                operation = FollowHashtagOperation(hashtag: hashtag)
            }
            operation.queue()
        }
        return cell
    }
    
    func updateFollowControlState(followControl: VFollowControl?, forHashtag hashtag: String, animated: Bool = true) {
        guard let followControl = followControl, currentUser = VCurrentUser.user() else {
            return
        }
        let controlState: VFollowControlState
        if currentUser.isFollowingHashtagString(hashtag) {
            controlState = .Followed
        } else {
            controlState = .Unfollowed
        }
        followControl.setControlState(controlState, animated: animated)
    }
}