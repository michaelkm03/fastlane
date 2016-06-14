//
//  ContentDeepLinkHandler.swift
//  victorious
//
//  Created by Vincent Ho on 6/2/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import UIKit

class ContentDeepLinkHandler: NSObject, VDeeplinkHandler {
    static let contentDeeplinkURLHostComponent = "content"
    
    private var dependencyManager: VDependencyManager
    private weak var originViewController: UIViewController?
    
    init(dependencyManager: VDependencyManager, originViewController: UIViewController) {
        self.dependencyManager = dependencyManager
        self.originViewController = originViewController
    }
    
    var requiresAuthorization = false
    
    func displayContentForDeeplinkURL(url: NSURL, completion: VDeeplinkHandlerCompletionBlock?) {
        guard canDisplayContentForDeeplinkURL(url),
            let contentID = url.v_firstNonSlashPathComponent(),
            let originViewController = originViewController else {
            completion?(false, nil)
            return
        }
        
        let displayModifier = ShowCloseUpDisplayModifier(dependencyManager: dependencyManager, originViewController: originViewController)
        ShowCloseUpOperation.showOperation(forContentID: contentID, displayModifier: displayModifier).queue() { error, cancelled in
            let finished = (error == nil) && !cancelled
            completion?(finished, nil)
        }
        
    }
    
    func canDisplayContentForDeeplinkURL(url: NSURL) -> Bool {
        let isHostValid = url.host == ContentDeepLinkHandler.contentDeeplinkURLHostComponent
        let isContentValid = url.v_firstNonSlashPathComponent() != nil
        return isHostValid && isContentValid
    }
}