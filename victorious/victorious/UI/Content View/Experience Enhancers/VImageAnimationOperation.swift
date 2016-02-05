//
//  VImageAnimationOperation.swift
//  victorious
//
//  Created by Vincent Ho on 1/26/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import UIKit

@objc protocol VImageAnimationOperationDelegate {
    /// Should remove imageview after this call
    func animation(animation: VImageAnimationOperation, didFinishAnimating completed:Bool)
    
    /// Should update UIImageView
    func animation(animation: VImageAnimationOperation, updatedToImage image:UIImage?)
}

class VImageAnimationOperation: Operation {
    
    weak var delegate: VImageAnimationOperationDelegate?
    
    var animationImageView: UIImageView = UIImageView()
    var animationDuration: Float = 0
    var animationSequence = [UIImage]()
    private var currentFrame: Int = -1
    private var animationTimer: NSTimer = NSTimer()
    var ballisticAnimationBlock: (( ()->() )->(Void))?
    
    func isAnimating() -> Bool {
        if completedAnimation() {
            return false
        }
        return currentFrame != -1
    }
    
    /// If nil or empty animation sequence, by default the animation is done.
    func completedAnimation() -> Bool {
        if animationSequence.isEmpty {
            return true
        }
        else {
            return currentFrame == animationSequence.count
        }
    }
    
    func updateFrame() {
        updateImageFrame()
        currentFrame++
    }
    
    func updateImageFrame() {
        if cancelled || completedAnimation() {
            stopAnimating()
        }
        else {
            let image: UIImage? = animationSequence[currentFrame]
            delegate?.animation(self, updatedToImage: image)
        }
    }
    
    func beginAnimation() {
        if let ballisticAnimationBlock = ballisticAnimationBlock {
            ballisticAnimationBlock(){
                self.currentFrame = 0
                NSRunLoop.mainRunLoop().addTimer(self.animationTimer, forMode: NSDefaultRunLoopMode)
            }
        }
        else {
            NSRunLoop.mainRunLoop().addTimer(animationTimer, forMode: NSDefaultRunLoopMode)
        }
    }
    
    func startAnimating() {
        currentFrame = 0
        if animationSequence.isEmpty {
            stopAnimating()
        }
        else {
            let frameDuration: Float = animationDuration/Float(animationSequence.count)
            animationTimer = NSTimer(timeInterval: NSTimeInterval(frameDuration), target: self, selector: "updateFrame", userInfo: nil, repeats: true)
            beginAnimation()
        }
    }
    
    func stopAnimating() {
        delegate?.animation(self, updatedToImage: nil)
        let finishedAnimation: Bool = currentFrame == animationSequence.count
        delegate?.animation(self, didFinishAnimating:finishedAnimation)
        animationTimer.invalidate()
        finishedExecuting()
    }
    
    override func start() {
        startAnimating()
        super.start()
    }
    
    override func cancel() {
        stopAnimating()
        super.cancel()
    }
}