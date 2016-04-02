//
//  InterstitialAlertPresentationController.swift
//  victorious
//
//  Created by Cody Kolodziejzyk on 9/28/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import UIKit
import Foundation

class InterstitialAlertPresentationController: UIPresentationController {
    
    private lazy var dimmingView = UIView()
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else {
            return
        }
        
        dimmingView.backgroundColor = UIColor.blackColor()
        dimmingView.alpha = 0
        dimmingView.frame = containerView.bounds
        containerView.addSubview(dimmingView)
        
        UIView.animateWithDuration(0.3) {
            self.dimmingView.alpha = 0.75
        }
    }
    
    override func presentationTransitionDidEnd(completed: Bool) {
        if !completed {
            dimmingView.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionWillBegin() {
        guard let transitionCoordinator = self.presentingViewController.transitionCoordinator() else {
            return
        }
        
        // Fade in the dimming view alongside the transition
        transitionCoordinator.animateAlongsideTransition({ (context) in
            self.dimmingView.alpha = 0
        }, completion: nil)
    }
    
    override func dismissalTransitionDidEnd(completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
        }
    }
}