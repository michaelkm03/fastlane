//
//  RESTForumNetworkSource.swift
//  victorious
//
//  Created by Jarod Long on 5/18/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

class RESTForumNetworkSource: NSObject, ForumNetworkSource {
    
    // MARK: - Initialization
    
    init(dependencyManager: VDependencyManager) {
        self.dependencyManager = dependencyManager.networkResources ?? dependencyManager
        
        dataSource = TimePaginatedDataSource(apiPath: self.dependencyManager.mainFeedAPIPath) {
            ContentFeedOperation(url: $0)
        }
    }
    
    // MARK: - Dependency manager
    
    private let dependencyManager: VDependencyManager
    
    // MARK: - Data source
    
    let dataSource: TimePaginatedDataSource<ContentModel, ContentFeedOperation>
    
    // MARK: - Polling
    
    private static let pollingInterval = NSTimeInterval(10.0)
    
    private var pollingTimer: VTimerManager?
    
    private func startPolling() {
        pollingTimer?.invalidate()
        
        pollingTimer = VTimerManager.scheduledTimerManagerWithTimeInterval(
            RESTForumNetworkSource.pollingInterval,
            target: self,
            selector: #selector(pollForNewContent),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc private func pollForNewContent() {
        dataSource.loadItems(.newer) { [weak self] contents, error in
            self?.broadcast(.appendContent(contents.reverse().map { $0.toSDKContent() }))
        }
    }
    
    // MARK: - ForumNetworkSource
    
    func setUp() {
        isSetUp = true
        
        dataSource.loadItems(.refresh) { [weak self] contents, error in
            self?.broadcast(.appendContent(contents.reverse().map { $0.toSDKContent() }))
        }
        
        startPolling()
    }
    
    func tearDown() {
        // Nothing to tear down.
    }
    
    func addChildReceiver(receiver: ForumEventReceiver) {
        if !childEventReceivers.contains({ $0 === receiver }) {
            childEventReceivers.append(receiver)
        }
    }
    
    func removeChildReceiver(receiver: ForumEventReceiver) {
        if let index = childEventReceivers.indexOf({ $0 === receiver }) {
            childEventReceivers.removeAtIndex(index)
        }
    }
    
    private(set) var isSetUp = false
    
    // MARK: - ForumEventSender
    
    private(set) weak var nextSender: ForumEventSender?
    
    func send(event: ForumEvent) {
        nextSender?.send(event)
        
        switch event {
        case .loadOldContent:
            dataSource.loadItems(.older) { [weak self] contents, error in
                self?.broadcast(.prependContent(contents.reverse().map { $0.toSDKContent() }))
            }
        default:
            break
        }
    }
    
    // MARK: - ForumEventReceiver
    
    private(set) var childEventReceivers = [ForumEventReceiver]()
    
    func receive(event: ForumEvent) {
        // Nothing yet.
    }
}

private extension VDependencyManager {
    var mainFeedAPIPath: String {
        guard let apiPath = stringForKey("mainFeedUrl") else {
            assertionFailure("Failed to retrieve main feed API path from dependency manager.")
            return ""
        }
        
        return apiPath
    }
}