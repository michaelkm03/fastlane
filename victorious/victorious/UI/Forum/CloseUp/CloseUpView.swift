//
//  CloseUpView.swift
//  victorious
//
//  Created by Vincent Ho on 4/15/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import UIKit

protocol CloseUpViewDelegate {
    func didSelectProfile()
}

class CloseUpView: UIView, ConfigurableGridStreamHeader {
    @IBOutlet weak var headerSection: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameButton: UIButton!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var mediaContentView: MediaContentView!
    @IBOutlet weak var captionLabel: UILabel!
    
    private var videoPlayer: VVideoPlayer?
    private var previewView: VSequencePreviewView!
    private let placeholderImage = UIImage(named: "profile_full")
    private let horizontalMargins: CGFloat = 16
    private let verticalMargins:CGFloat = 18
    
    class func newWithDependencyManager(dependencyManager: VDependencyManager,
                                        delegate: CloseUpViewDelegate? = nil) -> CloseUpView {
        guard let view = NSBundle.mainBundle().loadNibNamed("CloseUpView",
                                                            owner: self,
                                                            options: nil).first as? CloseUpView else {
                                                                fatalError("Could not load a close up view.")
        }
        view.dependencyManager = dependencyManager
        view.delegate = delegate
        return view
    }
    
    override func awakeFromNib() {
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2.0
        clearContent()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(closeUpDismissed),
                                                         name: "closeUpDismissed",
                                                         object: nil)
    }
    
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var blurredImageView: UIImageView!
    var dependencyManager: VDependencyManager!
    var delegate: CloseUpViewDelegate?
    
    @IBAction func selectedProfile(sender: AnyObject) {
        delegate?.didSelectProfile()
    }
    
    func clearContent() {
        captionLabel.text = ""
        profileImageView.image = nil
        userNameButton.setTitle("", forState: UIControlState.Normal)
        createdAtLabel.text = ""
        previewView = nil
    }
    
    var maxHeight: CGFloat = CGFloat.max
    
    var content: CloseUpContent? {
        didSet {
            // TODO: Set fonts/colors based on dependency manager
            guard let content = content else {
                return
            }
            // Header
            userNameButton.setTitle(content.user.name, forState: UIControlState.Normal)
            if let picturePath = content.user.pictureUrl, pictureURL = NSURL(string: picturePath) {
                profileImageView.sd_setImageWithURL(pictureURL,
                                                    placeholderImage: placeholderImage)
            }
            else {
                profileImageView.image = placeholderImage
            }
            blurredImageView.applyBlurToImageURL(content.previewImageURL, withRadius: 10.0)
            
            createdAtLabel.text = content.creationDate?.stringDescribingTimeIntervalSinceNow(format: .concise, precision: .seconds) ?? ""
            captionLabel.text = content.title
            mediaContentView.content = content
            
            // Update size
            self.frame.size = sizeForContent(content)
        }
    }
    
    override func layoutSubviews() {
        guard let content = content else {
            return
        }
        
        var totalHeight = CGRectGetHeight(headerSection.bounds)
        
        let screenWidth = CGRectGetWidth(UIScreen.mainScreen().bounds)
        let aspectRatio = content.aspectRatio // width to height ratio
        let contentHeight: CGFloat = min(screenWidth / aspectRatio, maxHeight - CGRectGetHeight(headerSection.bounds))
        
        // Content
        var mediaContentViewFrame = mediaContentView.frame
        mediaContentViewFrame.origin.y = totalHeight
        mediaContentViewFrame.size.height = contentHeight
        mediaContentView.frame = mediaContentViewFrame
        
        if previewView != nil {
            previewView.removeFromSuperview()
        }
        
        // TODO: Set up preview view
        
        totalHeight = totalHeight + CGRectGetHeight(mediaContentView.bounds)
        
        // Caption
        var frame = captionLabel.frame
        frame.origin.y = totalHeight + verticalMargins
        frame.size.width = screenWidth - 2 * horizontalMargins
        captionLabel.frame = frame
        captionLabel.sizeToFit()
        
    }
    
    func sizeForContent(content: CloseUpContent) -> CGSize {
        let screenWidth = CGRectGetWidth(UIScreen.mainScreen().bounds)
        let aspectRatio = content.aspectRatio // width to height ratio
        let contentHeight: CGFloat = min(screenWidth / aspectRatio, maxHeight - CGRectGetHeight(headerSection.bounds))
        
        if !contentHasTitle(content) {
            return CGSizeMake(screenWidth, CGRectGetHeight(headerSection.bounds) + contentHeight)
        }
        
        var frame = captionLabel.frame
        frame.size.width = screenWidth - 2 * horizontalMargins
        captionLabel.frame = frame
        captionLabel.text = content.title
        captionLabel.sizeToFit()
        
        let height = CGRectGetHeight(headerSection.bounds) + contentHeight + CGRectGetHeight(captionLabel.bounds) + 2*verticalMargins
        return CGSizeMake(screenWidth, height)
    }
    
    private func contentHasTitle(content: CloseUpContent) -> Bool {
        if content.title.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).characters.count == 0 {
            return false
        }
        return true
    }
    
    @objc private func closeUpDismissed() {
        if let videoPlayer = videoPlayer {
            print(videoPlayer)
            dispatch_async(dispatch_get_main_queue(), {
                videoPlayer.pause()
            })
        }
    }
    
    // MARK: - ConfigurableHeader
    
    func decorateHeader(dependencyManager: VDependencyManager,
                        maxHeight: CGFloat,
                        content: CloseUpContent) {
        //        self.maxHeight = maxHeight
        self.content = content
    }
    
    func sizeForHeader(dependencyManager: VDependencyManager,
                       maxHeight: CGFloat,
                       content: CloseUpContent) -> CGSize
    {
        return sizeForContent(content)
    }
}
