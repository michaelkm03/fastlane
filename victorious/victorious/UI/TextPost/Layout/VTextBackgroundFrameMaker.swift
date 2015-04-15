//
//  VTextBackgroundFrameMaker.swift
//  victorious
//
//  Created by Patrick Lynch on 4/13/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

import UIKit

/**
Generates background rectangles to be rendered behind a text view to provide an enclosed or "label maker" effect.
Text within the specified callout ranges is given a special treatment that provides separate background frames
that are broken apart or "called out" from the main rectangle of the surrounding line of text.
*/
@objc class VTextBackgroundFrameMaker: NSObject
{
    let fragmentsBuilder = VTextFragmentsBuilder()
    
    /**
    Creates an array of background frames as CGRects for using properies of the provided text view.
    This will not automatically set the background frames to be renered.  That is the reponsibility
    of calling code.
    */
    func createBackgroundFramesForTextView( textView: UITextView, characterWidth: CGFloat, calloutRangeObjects: NSArray ) -> NSArray
    {
        let calloutRanges: [NSRange] = map( calloutRangeObjects, { ($0 as! NSValue).rangeValue } )
        textView.textContainer.size = CGSizeMake( textView.bounds.size.width, CGFloat.max )
        var fragments = self.fragmentsBuilder.fragmentsInTextView( textView, calloutRanges: calloutRanges )
        self.fragmentsBuilder.applySpacingToFragments( fragments, spacing: 1.0, horizontalOffset: characterWidth )
        
        return fragments.map { NSValue( CGRect: $0.rect ) }
    }
}