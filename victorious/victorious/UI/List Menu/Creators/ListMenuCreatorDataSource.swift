//
//  ListMenuCreatorDataSource.swift
//  victorious
//
//  Created by Tian Lan on 4/21/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation

final class ListMenuCreatorDataSource: ListMenuSectionDataSource {
    typealias Cell = ListMenuCreatorCollectionViewCell
    
    let dependencyManager: VDependencyManager
    
    init(dependencyManager: VDependencyManager) {
        self.dependencyManager = dependencyManager
    }
    
    // MARK: - List Menu Section Data Source
    
    private(set) var visibleItems: [UserModel] = [] {
        didSet {
            state = visibleItems.isEmpty ? .noContent : .items
            delegate?.didUpdateVisibleItems(forSection: .creator)
        }
    }

    private(set) var state: ListMenuDataSourceState = .loading
    
    weak var delegate: ListMenuSectionDataSourceDelegate?
    
    func fetchRemoteData() {
        guard let creatorListAPIPath = dependencyManager.creatorListAPIPath else {
            Log.info("nil endpoint url for list of creators on left nav")
            return
        }
        
        let operation = RequestOperation(
            request: CreatorListRequest(apiPath: creatorListAPIPath)
        )
        
        operation.queue { [weak self] result in
            switch result {
                case .success(let users):
                    self?.visibleItems = users
                case .failure(let error):
                    self?.state = .failed(error: error)
                    self?.delegate?.didUpdateVisibleItems(forSection: .creator)
                case .cancelled:
                    break
            }
        }
    }
}

private extension VDependencyManager {
    var creatorListAPIPath: APIPath? {
        return apiPathForKey("listOfCreatorsURL")
    }
}
