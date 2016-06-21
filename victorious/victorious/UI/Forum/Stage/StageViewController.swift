//
//  StageViewController.swift
//  victorious
//
//  Created by Sharif Ahmed on 3/1/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import UIKit
import VictoriousIOSSDK
import SDWebImage

class StageViewController: UIViewController, Stage, VVideoPlayerDelegate {
    private struct Constants {
        static let contentSizeAnimationDuration: NSTimeInterval = 0.5
        static let defaultAspectRatio: CGFloat = 16 / 9
        
        static let pillInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        static let pillHeight: CGFloat = 30
        static let pillBottomMargin: CGFloat = 20
    }
    
    @IBOutlet private var mediaContentView: MediaContentView!
    private lazy var newItemPill: TextOnColorButton = {
        let pill = TextOnColorButton()
        pill.dependencyManager = self.dependencyManager.newItemButtonDependency
        pill.contentEdgeInsets = Constants.pillInsets
        pill.sizeToFit()
        pill.clipsToBounds = true
        return pill
    }()
    
    private var stageDataSource: StageDataSource?
    
    weak var delegate: StageDelegate?
    
    var dependencyManager: VDependencyManager! {
        didSet {
            // The data source is initialized with the dependency manager since it needs URLs in the template to operate.
            stageDataSource = setupDataSource(dependencyManager)
        }
    }
    
    override func viewDidLoad() {
        view.addSubview(newItemPill)
        view.v_addPinToBottomToSubview(newItemPill, bottomMargin: Constants.pillBottomMargin)
        view.v_addCenterHorizontallyConstraintsToSubview(newItemPill)
        newItemPill.v_addHeightConstraint(Constants.pillHeight)
    }

    // MARK: Life cycle
    
    private func setupDataSource(dependencyManager: VDependencyManager) -> StageDataSource {
        let dataSource = StageDataSource(dependencyManager: dependencyManager)
        dataSource.delegate = self
        return dataSource
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        mediaContentView.allowsVideoControls = false
        mediaContentView.videoCoordinator?.playVideo()
    }

    override func viewWillDisappear(animated: Bool) {
        hideStage()
    }
    
    //MARK: - Stage
    
    func addContent(stageContent: ContentModel) {
        mediaContentView.videoCoordinator?.pauseVideo()
        mediaContentView.content = stageContent
        
        let defaultStageHeight = view.bounds.width / Constants.defaultAspectRatio
        delegate?.stage(self, didUpdateContentHeight: defaultStageHeight)
    }

    func removeContent() {
        hideStage()
    }

    // MARK: - ForumEventReceiver
    
    var childEventReceivers: [ForumEventReceiver] {
        return [stageDataSource].flatMap { $0 }
    }

    // MARK: Clear Media
    
    private func hideStage(animated: Bool = false) {
        mediaContentView.videoCoordinator?.pauseVideo()
        mediaContentView.hideContent(animated: animated)
        
        UIView.animateWithDuration(animated == true ? Constants.contentSizeAnimationDuration : 0) {
            self.view.layoutIfNeeded()
        }
        self.delegate?.stage(self, didUpdateContentHeight: 0.0)
    }
}

private extension VDependencyManager {
    var newItemButtonDependency: VDependencyManager? {
        return childDependencyForKey("newItemButton")
    }
}
