//
//  VCommentMediaView.swift
//  victorious
//
//  Created by Cody Kolodziejzyk on 7/29/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

import Foundation

enum MediaAttachmentType {
    case Image, Video, Ballistic, GIF, NoMedia
    var description : String {
        switch (self) {
        case .Image:
            return "Image"
        case .Video:
            return "Video"
        case .Ballistic:
            return "Ballistic"
        case .GIF:
            return "GIF"
        default:
            return "NoMedia"
        }
    }
    
    static func attachmentType(comment: VComment) -> MediaAttachmentType {
        let commentMediaType = comment.commentMediaType()
        switch (commentMediaType) {
        case .Image:
            return .Image
        case .Video:
            return .Video
        case .GIF:
            return .GIF
        case .Ballistic:
            return .Ballistic
        default:
            return .NoMedia
        }
    }
    
    static func attachmentType(message: VMessage) -> MediaAttachmentType {
        let messageMediaType = message.messageMediaType()
        switch (messageMediaType) {
        case .Image:
            return .Image
        case .Video:
            return .Video
        default:
            return .NoMedia
        }
    }
}

protocol Focus {
    var hasFocus: Bool { get set }
}

protocol Reuse {
    func prepareForReuse()
}

class MediaAttachmentView : UIView, Focus, Reuse {
    
    var comment: VComment?
    var message: VMessage?
    var respondToButton:((previewImage: UIImage?) -> Void)?
    var hasFocus = false
    var dependencyManager: VDependencyManager?
    
    // Factory method for returning correct concrete subclass with a comment
    class func mediaViewWithComment(comment: VComment) -> MediaAttachmentView? {
        let attachmentType = MediaAttachmentType.attachmentType(comment)
        let mediaAttachmentView = MediaAttachmentView.mediaViewFactory(attachmentType)
        if let unwrapped = mediaAttachmentView {
            unwrapped.comment = comment
            return unwrapped
        }
        return mediaAttachmentView
    }
    
    // Factory method for returning correct concrete subclass with a comment
    class func mediaViewWithMessage(message: VMessage) -> MediaAttachmentView? {
        let attachmentType = MediaAttachmentType.attachmentType(message)
        let mediaAttachmentView = MediaAttachmentView.mediaViewFactory(attachmentType)
        if let unwrapped = mediaAttachmentView {
            unwrapped.message = message
            return unwrapped
        }
        return mediaAttachmentView
    }
    
    class func mediaViewFactory(type: MediaAttachmentType) -> MediaAttachmentView? {
        var retVal: MediaAttachmentView?
        
        switch (type) {
        case .Image:
            retVal = MediaAttachmentImageView()
        case .Video:
            retVal = MediaAttachmentVideoView()
        case .GIF:
            retVal = MediaAttachmentGIFView()
        case .Ballistic:
            retVal = MediaAttachmentBallisticView()
        default:
            retVal = nil
        }
        
        return retVal
    }
    
    // Returns an cell reuse identifer for the proper concrete subclass
    class func reuseIdentifierForComment(comment: VComment) -> String {
        return MediaAttachmentType.attachmentType(comment).description
    }
    
    // Returns an cell reuse identifer for the proper concrete subclass
    class func reuseIdentifierForMessage(message: VMessage) -> String {
        return MediaAttachmentType.attachmentType(message).description
    }
    
    func prepareForReuse() {
        // Subclasses can override
    }
}

class MediaAttachmentImageView : MediaAttachmentView {
    
    let imageView = UIImageView()
    let mediaButton = UIButton()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    private func sharedInit() {
        
        self.mediaButton.addTarget(self, action: "mediaButtonPressed", forControlEvents: .TouchUpInside)
        
        self.addSubview(imageView)
        self.addSubview(mediaButton)
        
        self.v_addFitToParentConstraintsToSubview(imageView)
        self.v_addFitToParentConstraintsToSubview(mediaButton)
    }
    
    override var comment: VComment? {
        didSet {
            if let unwrapped = comment {
                self.previewImageURL = unwrapped.previewImageURL()
            }
        }
    }
    
    override var message: VMessage? {
        didSet {
            if let unwrapped = message {
                self.previewImageURL = unwrapped.previewImageURL()
            }
        }
    }
    
    var previewImageURL: NSURL? {
        didSet {
            self.imageView.alpha = 0
            if let previewURL = previewImageURL {
                self.imageView.sd_setImageWithURL(previewURL, completed: {
                    (image: UIImage!, error: NSError!, cacheType: SDImageCacheType, url: NSURL!) -> Void in
                    
                    if (error != nil)
                    {
                        return;
                    }
                    
                    self.imageView.image = image
                    
                    UIView.animateWithDuration(0.2, animations: { () -> Void in
                        self.imageView.alpha = 1
                    })
                })
            }
        }
    }
    
    func mediaButtonPressed() {
        if let completion = self.respondToButton {
            completion(previewImage: self.imageView.image)
        }
    }
}

class MediaAttachmentVideoView : MediaAttachmentImageView {
    
    let playIcon = UIImageView(image: UIImage(named: "PlayIcon"))
    
    private override func sharedInit() {
        super.sharedInit()
        
        self.addSubview(self.playIcon)
        self.v_addCenterToParentContraintsToSubview(self.playIcon)
    }
}

class MediaAttachmentGIFView : MediaAttachmentView {
    
    let videoView = VVideoView()
    
    override var hasFocus: Bool {
        didSet {
            hasFocus ? self.videoView.play() : self.videoView.pause()
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    private func sharedInit() {
        self.addSubview(self.videoView)
        self.v_addFitToParentConstraintsToSubview(self.videoView)
    }
    
    override var comment: VComment? {
        didSet {
            if let autoplayURL = comment?.properMediaURLGivenContentType() {
                self.videoView.setItemURL(autoplayURL, loop: true, audioMuted: true)
                self.videoView.hidden = false
            }
        }
    }
}

class MediaAttachmentBallisticView : MediaAttachmentView {
    
    let ballisticView = ExperienceEnhancerIconView(frame: CGRectZero)
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    private func sharedInit() {
        self.ballisticView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(self.ballisticView)
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[ballisticView(50)]", options: nil, metrics: nil, views: ["ballisticView": self.ballisticView])
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[ballisticView(50)]", options: nil, metrics: nil, views: ["ballisticView": self.ballisticView])
        self.addConstraints(vConstraints)
        self.addConstraints(hConstraints)
    }
    
    override var comment: VComment? {
        didSet {
            if let iconURLString = comment?.properMediaURLGivenContentType() {
                // WARNING: testing
                self.ballisticView.iconURL = NSURL(string: "http://media-dev-public.s3-website-us-west-1.amazonaws.com/_static/ballistics/6/icon/heart_icon.png")
//                self.ballisticView.iconURL = iconURLString
            }
        }
    }
    
    override var dependencyManager: VDependencyManager? {
        didSet {
            if let unwrappedDM = dependencyManager {
                self.ballisticView.tintColor = unwrappedDM.colorForKey(VDependencyManagerAccentColorKey)
            }
        }
    }
}
