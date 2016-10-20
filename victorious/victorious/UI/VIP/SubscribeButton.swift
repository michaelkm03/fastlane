//
//  SubscribeButton.swift
//  victorious
//
//  Created by Jarod Long on 8/15/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import UIKit

/// A reusable button that can be used for navigating to the VIP subscription flow.
///
/// If the user is already a VIP subscriber, then this will show a non-interactive icon instead.
///
class SubscribeButton: UIView {
    // MARK: - Initializing
    
    init(dependencyManager: VDependencyManager) {
        self.dependencyManager = dependencyManager
        userIsVIPButton = dependencyManager.userIsVIPButton
        
        super.init(frame: CGRect.zero)
        
        guard dependencyManager.subscriptionEnabled else {
            isHidden = true
            return
        }
        
        subscribeButton.translatesAutoresizingMaskIntoConstraints = false
        userIsVIPButton?.translatesAutoresizingMaskIntoConstraints = false
        
        subscribeButton.setTitle(NSLocalizedString("Upgrade", comment: ""), for: .normal)
        subscribeButton.sizeToFit()
        subscribeButton.addTarget(self, action: #selector(subscribeButtonWasPressed), for: .touchUpInside)
        updateVIPState()
        
        NotificationCenter.default.addObserver(self, selector: #selector(userStatusDidChange), name: NSNotification.Name(rawValue: VCurrentUser.userDidUpdateNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userStatusDidChange), name: NSNotification.Name.loggedInChanged, object: nil)
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported.")
    }
    
    // MARK: - Dependency manager
    
    private let dependencyManager: VDependencyManager
    
    // MARK: - Subviews
    
    private let subscribeButton = BackgroundButton(type: .system)
    private let userIsVIPButton: UIButton?
    
    private var visibleButton: UIButton? {
        return userIsVIP == true ? userIsVIPButton : subscribeButton
    }
    
    private var hiddenButton: UIButton? {
        return userIsVIP == true ? subscribeButton : userIsVIPButton
    }
    
    // MARK: - Actions
    
    private dynamic func subscribeButtonWasPressed() {
        guard let scaffold = VRootViewController.shared()?.scaffold else {
            return
        }
        
        Router(originViewController: scaffold, dependencyManager: dependencyManager).navigate(to: .vipSubscription, from: nil)
    }
    
    // MARK: - Responding to VIP changes
    
    private var userIsVIP: Bool? {
        didSet {
            guard userIsVIP != oldValue else {
                return
            }
            
            if let visibleButton = visibleButton {
                addSubview(visibleButton)
                visibleButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                visibleButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }
            
            hiddenButton?.removeFromSuperview()
            invalidateIntrinsicContentSize()
        }
    }
    
    private func updateVIPState() {
        userIsVIP = VCurrentUser.user?.hasValidVIPSubscription == true
    }
    
    private dynamic func userStatusDidChange(_ notification: Notification) {
        updateVIPState()
    }
    
    // MARK: - Layout
    
    override var intrinsicContentSize : CGSize {
        return (visibleButton ?? subscribeButton).intrinsicContentSize
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return intrinsicContentSize
    }
}

private extension VDependencyManager {
    var userIsVIPButton: UIButton? {
        return button(forKey: "button.vip")
    }
    
    var subscriptionEnabled: Bool {
        return childDependency(forKey: "subscription")?.number(forKey: "enabled")?.boolValue == true
    }
}
