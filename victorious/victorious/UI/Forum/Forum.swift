//
//  Forum.swift
//  victorious
//
//  Created by Patrick Lynch on 3/16/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation

/// Defines an object that requires these few properties in order to execute
/// the highest-level, abstract Forum business logic.  Plug and play :)
protocol Forum: ForumEventReceiver, ForumEventSender, ChatFeedDelegate, ComposerDelegate, StageDelegate {
    
    // MARK: - Concrete dependencies
    
    var dependencyManager: VDependencyManager! { get }
    var originViewController: UIViewController { get }
    
    // MARK: - Behaviors
    
    var stage: Stage? { get }
    var composer: Composer? { get }
    var chatFeed: ChatFeed? { get }
    
    // MARK: - Behaviors

    func setStageHeight(value: CGFloat)
    func setComposerHeight(value: CGFloat)
}

/// The default implementation of the highest-level, abstract Forum business logic,
/// intended as a concise and flexible mini-architecture and defines the
/// most fundamental interation between parent and subcomponents.
extension Forum {
    
    // MARK: - ForumEventReceiver
    
    var childEventReceivers: [ForumEventReceiver] {
        return [ stage as? ForumEventReceiver, chatFeed as? ForumEventReceiver ].flatMap { $0 }
    }
    
    // MARK: - ChatFeedDelegate
    
    func chatFeed(chatFeed: ChatFeed, didSelectUserWithUserID userID: Int) {
        ShowProfileOperation(originViewController: originViewController,
            dependencyManager: dependencyManager,
            userId: userID).queue()
    }
    
    func chatFeed(chatFeed: ChatFeed, didSelectMedia media: ForumMedia) {
        
    }
    
    // MARK: - ComposerDelegate
    
    func composer(composer: Composer, didSelectCreationType creationType: VCreationType) {
        let presenter = VCreationFlowPresenter(dependencymanager: dependencyManager)
        presenter.shouldShowPublishScreenForFlowController = false
        presenter.presentWorkspaceOnViewController(originViewController, creationType: creationType)
    }
    
    func composer(composer: Composer, didConfirmWithMedia media: MediaAttachment?, caption: String?) {
        let event = ForumEvent(
            media: nil,
            messageText: caption,
            date: NSDate()
        )
        sendEvent(event)
    }
    
    func composer(composer: Composer, didUpdateToContentHeight height: CGFloat) {
        setComposerHeight(height)
    }
    
    // MARK: - StageDelegate
    
    func stage(stage: Stage, didUpdateContentSize size: CGSize) {
        setStageHeight(size.height)
        chatFeed?.setTopInset(size.height)
    }
    
    func stage(stage: Stage, didUpdateWithMedia media: Stageable) {
        
    }
    
    func stage(stage: Stage, didSelectMedia media: Stageable) {
        
    }
}
