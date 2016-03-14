//
//  ForumViewController.swift
//  victorious
//
//  Created by Patrick Lynch on 3/9/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation

class ForumViewController: UIViewController, ComposerDelegate {

    @IBOutlet private var chatFeedViewControllerContainer: UIView!
    
    @IBOutlet private var composerViewControllerContainer: UIView!
    
    @IBOutlet private var stageViewControllerContainer: UIView!
    
    @IBOutlet private var composerViewControllerHeightConstraint: NSLayoutConstraint!
    
    private var dependencyManager: VDependencyManager!
    
    
    //MARK: - Initialization
    
    class func newWithDependencyManager( dependencyManager: VDependencyManager ) -> ForumViewController {
        
        let forumVC: ForumViewController = ForumViewController.v_initialViewControllerFromStoryboard("ForumViewController")
        forumVC.dependencyManager = dependencyManager
        return forumVC
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        super.prepareForSegue(segue, sender: sender)
        let destination = segue.destinationViewController
        if let stageViewController = destination as? StageViewController {
            stageViewController.dependencyManager = dependencyManager
        } else if let composerViewController = destination as? ComposerViewController {
            composerViewController.dependencyManager = dependencyManager
        }
        // Uncomment the following lines once the chat feed view controller is added
        // to the project.
//        else if let chatFeedViewController = destination as? ChatFeedViewController {
//            chatFeedViewController.dependencyManager = dependencyManager
//        }
    }
    
    //MARK: - ComposerDelegate
    
    func composer(composer: Composer, confirmedWithCaption: String) {
        
    }
    
    func composer(composer: Composer, confirmedWithMedia: MediaAttachment, caption: String?) {
        
    }
    
    func composer(composer: Composer, didSelectAttachmentTab: ComposerAttachmentTab) {
        
    }
    
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = dependencyManager.colorForKey(VDependencyManagerAccentColorKey)
        view.addGestureRecognizer( UITapGestureRecognizer(target: self, action: "exit") )
    }
    
    
    //MARK: - Actions
    
    func exit() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
