//
//  ForumViewController.swift
//  victorious
//
//  Created by Sharif Ahmed on 3/3/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import UIKit

/// A template driven .screen component that sets up, houses and mediates the interaction
/// between the Foumr's required concrete implementations and abstract dependencies.
class ForumViewController: UIViewController, Forum, VBackgroundContainer {

    @IBOutlet private weak var stageContainer: UIView! {
        didSet {
            stageContainer.layer.shadowColor = UIColor.blackColor().CGColor
            stageContainer.layer.shadowRadius = 8.0
            stageContainer.layer.shadowOpacity = 0.75
            stageContainer.layer.shadowOffset = CGSize(width:0, height:2)
        }
    }
    
    @IBOutlet private weak var stageContainerHeight: NSLayoutConstraint! {
        didSet {
            stageContainerHeight.constant = 0.0
        }
    }
    
    // MARK: - Initialization
    
    class func newWithDependencyManager( dependencyManager: VDependencyManager ) -> ForumViewController {
        let forumVC: ForumViewController = ForumViewController.v_initialViewControllerFromStoryboard("Forum")
        forumVC.dependencyManager = dependencyManager
        return forumVC
    }
    
    // MARK: - ForumEventReceiver
    
    var childEventReceivers: [ForumEventReceiver] {
        let children = [
            stage as? ForumEventReceiver,
            chatFeed as? ForumEventReceiver,
            composer as? ForumEventReceiver
        ]
        return children.flatMap { $0 }
    }
    
    func receiveEvent(event: ForumEvent) {
        let r = childEventReceivers
        for receiver in r {
            receiver.receiveEvent(event)
        }
        
        if let event = event as? WebSocketEvent {
            switch event.type {
            case .Disconnected(webSocketError: _):
                connectToNetworkSource()
            default: break
            }
        }
    }

    // MARK: - ForumEventSender
    
    var nextSender: ForumEventSender? //< Calling code just needs to set this to get messages propagated from composer.
    
    // MARK: - Forum protocol requirements
    
    var stage: Stage?
    var composer: Composer?
    var chatFeed: ChatFeed?
    var dependencyManager: VDependencyManager!
    var networkSource: NetworkSource?
    func creationFlowPresenter() -> VCreationFlowPresenter? {
        return composer?.creationFlowPresenter
    }
    
    var originViewController: UIViewController {
        return self
    }
    
    func setStageHeight(value: CGFloat) {
        stageContainerHeight.constant = value
        view.layoutIfNeeded()
    }
    
    // MARK: - VBackgroundContainer
    
    func backgroundContainerView() -> UIView {
        return view
    }
    
    // MARK: - UIViewController overrides
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //Remove this once the way to animate the workspace in and out from forum has been figured out
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // debug_startGeneratingMessages(interval: 1.0)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Exit", comment: ""),
            style: .Plain,
            target: self,
            action: #selector(onClose)
        )
        updateStyle()
        
        networkSource = dependencyManager.networkSource
        setupNetworkSource(networkSource!)
        connectToNetworkSource()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        let destination = segue.destinationViewController
        
        if let stage = destination as? Stage {
            stage.dependencyManager = dependencyManager.stageDependency
            stage.delegate = self
            self.stage = stage
            
        } else if let chatFeed = destination as? ChatFeed {
            chatFeed.dependencyManager = dependencyManager.chatFeedDependency
            chatFeed.delegate = self
            self.chatFeed = chatFeed
        
        } else if let composer = destination as? Composer {
            composer.dependencyManager = dependencyManager.composerDependency
            composer.delegate = self
            self.composer = composer
        
        } else {
            // Hide any embedded container views from which a component could not be loaded
            destination.view.superview?.hidden = true
        }
    }
    
    // MARK: Network Source
    
    func connectToNetworkSource() {
        if let socketNetworkAdapter = networkSource as? WebSocketNetworkAdapter where !socketNetworkAdapter.isConnected {
            socketNetworkAdapter.setUp()
        }
    }
    
    // MARK: - Actions
    
    func onClose() {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func updateStyle() {
        guard isViewLoaded() else {
            return
        }
        
        title = dependencyManager.title
        dependencyManager.applyStyleToNavigationBar(self.navigationController?.navigationBar)
        navigationController?.navigationBar.translucent = false
        dependencyManager.addBackgroundToBackgroundHost(self)
    }
    
    // MARK: - VCoachmarkDisplayer
    
    func screenIdentifier() -> String! {
        return dependencyManager.stringForKey(VDependencyManagerIDKey)
    }
    
    // MARK: Private
    
    private func setupNetworkSource(networkSource: NetworkSource) {
        // Add the network source as the next responder in the FEC.
        nextSender = networkSource
        // Inject ourselves into the child receiver list in order to link the chain together.
        networkSource.addChildReceiver(self)
    }
}

private extension VDependencyManager {
    
    var title: String? {
        return stringForKey("title.text")
    }
    
    var chatFeedDependency: VDependencyManager? {
        return childDependencyForKey("chatFeed")
    }
    
    var composerDependency: VDependencyManager? {
        return childDependencyForKey("composer")
    }
    
    var stageDependency: VDependencyManager? {
        return childDependencyForKey("stage")
    }
    
    var networkSource: WebSocketNetworkAdapter {
        return singletonObjectOfType(WebSocketNetworkAdapter.self, forKey: "networkLayerSource") as! WebSocketNetworkAdapter
    }
}
