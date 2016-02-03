//
//  VStreamCollectionViewController+AccessoryButtonResponder.swift
//  victorious
//
//  Created by Tian Lan on 12/17/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import UIKit

extension VStreamCollectionViewController {
    func showLegalInfoOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let tosAction = UIAlertAction(title: NSLocalizedString("ToSText", comment: ""),
            style: .Default) { alertAction in
                self.presentViewController(VTOSViewController.presentableTermsOfServiceViewController(),
                    animated: true,
                    completion: nil)
        }
        let privacyAction = UIAlertAction(title: NSLocalizedString("Privacy Policy", comment: ""),
            style: .Default) { alertAction in
                self.presentViewController(VPrivacyPoliciesViewController.presentableTermsOfServiceViewControllerWithDependencyManager(self.dependencyManager),
                    animated: true,
                    completion: nil)
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
            style: .Cancel,
            handler: nil)
        
        alert.addAction(tosAction)
        alert.addAction(privacyAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
}