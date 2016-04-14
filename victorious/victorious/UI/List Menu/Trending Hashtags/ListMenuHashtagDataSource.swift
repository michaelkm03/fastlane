//
//  ListMenuHashtagDataSource.swift
//  victorious
//
//  Created by Tian Lan on 4/11/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

class ListMenuHashtagDataSource: ListMenuSectionDataSource {
    
    private let dependencyManager: VDependencyManager
    
    // MARK: - Initialization
    
    /// Initializes a ListMenuHashtagDataSource, then start to fetch trending hashtags from backend
    init(dependencyManager: VDependencyManager, delegate: ListMenuSectionDataSourceDelegate) {
        self.delegate = delegate
        self.dependencyManager = dependencyManager
        
        fetchRemoteData()
    }
    
    // MARK: - List Menu Section Data Source
    
    /// An array of visible hashtags. This array starts with no hashtags,
    /// and gets populated after `fetchRemoteData` is called
    private(set) var visibleItems: [HashtagSearchResultObject] = [] {
        didSet {
            self.delegate.didUpdateVisibleItems(forSection: .hashtags)
        }
    }
    
    private(set) var delegate: ListMenuSectionDataSourceDelegate
    
    func fetchRemoteData() {
        let operation = TrendingHashtagOperation()
        operation.queue { [weak self] results, error, cancelled in
            guard let hashtags = results as? [HashtagSearchResultObject] else {
                return
            }
            self?.visibleItems = hashtags
        }
    }
}
