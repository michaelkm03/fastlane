//
//  VictoriousAPISerializer.swift
//  victorious
//
//  Created by Cody Kolodziejzyk on 9/8/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

import Foundation

/// A RKSerialization subclass that handles registering
/// any interstitials that it finds in the response
class VictoriousAPISerializer: NSObject, RKSerialization {
    
    static func objectFromData(data: NSData!, error: NSErrorPointer) -> AnyObject! {
        
        let responseObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: error)
        
        // Check if we have any interstitials to register
        if let responseObject = responseObject as? [String : AnyObject],
            interstitials = responseObject["alerts"] as? [[String : AnyObject]] {
                let parsedInterstitials = VictoriousAPISerializer.parseInterstitials(interstitials)
                if parsedInterstitials.count > 0 {
                    dispatch_async(dispatch_get_main_queue()) {
                        InterstitialManager.sharedInstance.registerInterstitials(parsedInterstitials)
                    }
                }
        }
        
        return responseObject
    }
    
    static func dataFromObject(object: AnyObject!, error: NSErrorPointer) -> NSData! {
        return NSJSONSerialization.dataWithJSONObject(object, options: nil, error: error)
    }
    
    // Class function for parsing interstitials
    private class func parseInterstitials(interstitials: [[String : AnyObject]]) -> [Interstitial] {
        var parsedInterstitials: [Interstitial] = []
        for interstitial in interstitials {
            // Instantiate and configure the correct interstitial sublass based on this payload
            if let configuredInterstitial = Interstitial.configuredInterstitial(interstitial) {
                parsedInterstitials.append(configuredInterstitial)
            }
        }
        
        return parsedInterstitials
    }
}