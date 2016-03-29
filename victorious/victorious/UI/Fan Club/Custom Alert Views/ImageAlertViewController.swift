//
//  ImageAlertViewController.swift
//  victorious
//
//  Created by Tian Lan on 3/28/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import UIKit

protocol CustomAlertView {
    var alert: Alert? { get set }
    func configure(withTitle title: String, detailedDescription detail: String, iconImageURL iconURL: NSURL?)
}

class ImageAlertViewController: UIViewController, CustomAlertView, InterstitialViewController, VBackgroundContainer {
    
    @IBOutlet private weak var iconImageView: UIImageView?
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var semiTransparentBackgroundButton: UIButton!
    @IBOutlet private weak var containerView: UIView!
    
    private var dependencyManager: VDependencyManager!
    
    private struct Constants {
        static let cornerRadius: CGFloat = 10
    }
    
    // MARK: - Initialization
    
    class func newWithDependencyManager(dependencyManager: VDependencyManager) -> ImageAlertViewController {
        let imageAlertViewController = ImageAlertViewController.v_initialViewControllerFromStoryboard() as ImageAlertViewController
        imageAlertViewController.dependencyManager = dependencyManager
        
        return imageAlertViewController
    }
    
    // MARK: - Custom Alert Protocol
    
    var alert: Alert?
    
    func configure(withTitle title: String, detailedDescription detail: String, iconImageURL iconURL: NSURL? = nil) {
        titleLabel.text = title
        detailLabel.text = detail

        if let iconURL = iconURL {
            iconImageView?.hidden = false
            iconImageView?.sd_setImageWithURL(iconURL)
        } else {
            iconImageView?.hidden = true
        }
    }
    
    // MARK: - InterstitialViewController Protocol
    
    weak var interstitialDelegate: InterstitialViewControllerDelegate?
    
    private let animator = AchievementAnimator()
    
    func presentationAnimator() -> UIViewControllerAnimatedTransitioning {
        return animator
    }
    
    func dismissalAnimator() -> UIViewControllerAnimatedTransitioning {
        animator.isDismissal = true
        return animator
    }
    
    func presentationController(presentedViewController: UIViewController, presentingViewController: UIViewController) -> UIPresentationController {
        return AchievementPresentationController(presentedViewController: presentedViewController, presentingViewController: presentingViewController)
    }
    
    func preferredModalPresentationStyle() -> UIModalPresentationStyle {
        return .Custom
    }
    
    // MARK: - VBackgroundContainer Protocol
    
    func backgroundContainerView() -> UIView {
        return containerView
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleComponents()
        if let alert = alert {
            configure(withTitle: alert.parameters.title, detailedDescription: alert.parameters.description, iconImageURL: alert.parameters.icons.first)
        } else {
        configure(withTitle: "Zootopia Quotes From Judy Hopps", detailedDescription: "I thought this city would be a perfect place where everyone got along and anyone could be anything. Turns out, life's a little bit more complicated than a slogan on a bumper sticker. Real life is messy. We all have limitations. We all make mistakes. Which means, hey, glass half full, we all have a lot in common. And the more we try to understand one another, the more exceptional each of us will be. But we have to try. So no matter what kind of person you are, I implore you: Try. Try to make the world a better place. Look inside yourself and recognize that change starts with you.", iconImageURL: nil)
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    @IBAction func dismiss(sender: UIButton) {
        interstitialDelegate?.dismissInterstitial(self)
    }
    
    // MARK: - Private Methods
    
    private func styleComponents() {
        containerView.layer.cornerRadius = Constants.cornerRadius
        
        titleLabel.font = dependencyManager.titleFont
        titleLabel.textColor = dependencyManager.textColor
        
        detailLabel.font = dependencyManager.detailLabelFont
        detailLabel.textColor = dependencyManager.textColor
        
        confirmButton.layer.cornerRadius = Constants.cornerRadius
        confirmButton.titleLabel?.font = dependencyManager.confirmButtonTitleFont
        confirmButton.setTitleColor(dependencyManager.confirmButtonTitleColor, forState: .Normal)
        confirmButton.setTitleColor(dependencyManager.confirmButtonTitleColor?.colorWithAlphaComponent(0.5), forState: .Highlighted)
        confirmButton.backgroundColor = dependencyManager.confirmButtonBackgroundColor
        confirmButton.setTitle(dependencyManager.confirmButtonTitle, forState: .Normal)
    }
}

private extension VDependencyManager {
    var confirmButtonBackgroundColor: UIColor? {
        return self.colorForKey(VDependencyManagerLinkColorKey)
    }
    
    var confirmButtonTitleFont: UIFont? {
        return self.fontForKey(VDependencyManagerHeading4FontKey)
    }
    
    var confirmButtonTitleColor: UIColor? {
        return self.colorForKey(VDependencyManagerContentTextColorKey)
    }
    
    var titleFont: UIFont? {
        return self.fontForKey(VDependencyManagerHeading3FontKey)
    }
    
    var detailLabelFont: UIFont? {
        return self.fontForKey(VDependencyManagerParagraphFontKey)
    }
    
    var textColor: UIColor? {
        return self.colorForKey(VDependencyManagerMainTextColorKey)
    }
    
    var confirmButtonTitle: String {
        return self.stringForKey("button.title") ?? NSLocalizedString("Dismiss Alert", comment: "")
    }
}
