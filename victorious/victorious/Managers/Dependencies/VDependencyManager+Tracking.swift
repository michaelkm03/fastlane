//
//  VDependencyManager+Tracking.swift
//  victorious
//
//  Created by Jarod Long on 9/20/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import VictoriousIOSSDK

private var associatedObjectViewWasHiddenKey = "viewWasHidden"

class TemplateTrackingKey: NSObject {
    static let start = "start"
    static let stop = "stop"
    static let appInit = "init"
    static let install = "install"
    static let createProfileStart = "create_profile_start"
    static let registrationStart = "registration_end"
    static let registrationEnd = "registration_end"
    static let createProfileDoneButtonTap = "create_profile_done_button_tap"
    static let registerButtonTap = "register_button_tap"
    static let signUpButtonTap = "sign_up_button_tap"
    static let permissionChange = "permission_change"
    static let appError = "error"
}


enum ButtonTrackingEvent: String {
    case tap = "button_tap"
    case cancel = "button_tap_cancel"
}

extension VDependencyManager {
    
    // MARK: - API paths
    
    /// The default key to use for tracking components in the template.
    static var defaultTrackingKey: String {
        return "tracking"
    }
    
    /// Returns a list of tracking API paths for the given keys, or nil if the paths cannot be found.
    ///
    /// The `trackingKey` is the key for the object that contains entries for each tracking event, which should be an
    /// immediate descendent of `self`. The `eventKey` is the key that should be used inside the tracking object for
    /// the specific event that you're looking for.
    ///
    /// For example, if the structure of `self` looks like this:
    ///
    /// ```
    /// {
    ///     "tracking": {
    ///         "view": ["http://some-tracking-url.com"]
    ///     }
    /// }
    /// ```
    ///
    /// Then `trackingKey` would be "tracking" and `eventKey` would be "view".
    ///
    func trackingAPIPaths(forEventKey eventKey: String, trackingKey: String = VDependencyManager.defaultTrackingKey) -> [APIPath]? {
        guard let tracking = templateValue(ofType: NSDictionary.self, forKey: trackingKey) as? [String: AnyObject] else {
            return nil
        }
        
        guard let urlStrings = tracking[eventKey] as? [String] else {
            return nil
        }
        
        return urlStrings.map { APIPath(templatePath: $0) }
    }
    
    // MARK: - View lifecycle
    
    func trackViewWillAppear(for viewController: UIViewController, parameters: [String: AnyObject] = [:]) {
        let wasHidden = (objc_getAssociatedObject(viewController, &associatedObjectViewWasHiddenKey) as? NSNumber)?.boolValue == true
        
        guard !wasHidden else {
            return
        }
        
        guard let apiPaths = trackingAPIPaths(forEventKey: "view") , apiPaths.count > 0 else {
            return
        }
        
        var parameters = parameters
        parameters[VTrackingKeyUrls] = (apiPaths.map { $0.templatePath }) as AnyObject?
        VTrackingManager.sharedInstance().trackEvent(VTrackingEventComponentDidBecomeVisible, parameters: parameters)
        
        objc_setAssociatedObject(viewController, &associatedObjectViewWasHiddenKey, NSNumber(value: true), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func trackViewWillDisappear(for viewController: UIViewController) {
        let navigationStack = viewController.navigationController?.viewControllers ?? []
        
        let navigationStackAfterViewController = navigationStack.index(of: viewController).flatMap {
            Array(navigationStack[$0 ..< navigationStack.count])
        } ?? []
        
        let wasHidden = navigationStackAfterViewController.count > 1 || viewController.presentedViewController != nil
        objc_setAssociatedObject(viewController, &associatedObjectViewWasHiddenKey, NSNumber(value: wasHidden), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    // MARK: - Objective-C compatibility
    
    func trackingURLStrings(forKey key: String) -> [String] {
        return trackingAPIPaths(forEventKey: key)?.flatMap { $0.templatePath } ?? []
    }
    
    func trackingURLs(forKey key: String) -> [String] {
        return trackingAPIPaths(forEventKey: key)?.flatMap { $0.url?.absoluteString } ?? []
    }
    
    func trackViewWillAppear(_ viewController: UIViewController) {
        trackViewWillAppear(for: viewController)
    }
    
    func trackViewWillDisappear(_ viewController: UIViewController) {
        trackViewWillDisappear(for: viewController)
    }

    // MARK: - Button Events

    func track(_ buttonEvent: ButtonTrackingEvent, trackingKey: String = VDependencyManager.defaultTrackingKey, macroReplacements: [String:String]? = nil, eventTracker: VEventTracker = VTrackingManager.sharedInstance()) {
        guard var apiPaths = trackingAPIPaths(forEventKey: buttonEvent.rawValue, trackingKey: trackingKey) , !apiPaths.isEmpty else {
            return
        }

        if let macroReplacements = macroReplacements {
            for index in apiPaths.indices {
                for (macro, value) in macroReplacements {
                    apiPaths[index].macroReplacements[macro] = value
                }
            }
        }

        eventTracker.trackEvent(buttonEvent.rawValue, parameters: [
            VTrackingKeyUrls: apiPaths.flatMap { $0.url?.absoluteString }
        ])
    }

}
