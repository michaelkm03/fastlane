//
//  LinkDetector.swift
//  victorious
//
//  Created by Jarod Long on 9/13/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation

/// A protocol that can be conformed to to provide detection of links inside a `LinkLabel`.
protocol LinkDetector {
    /// Returns the ranges inside `string` that should be highlighted as links.
    func detectLinks(in string: String) -> [Range<String.Index>]
    
    /// A callback that triggers when any links generated by this detector are tapped.
    var callback: ((_ matchedString: String) -> Void)? { get }
}

/// A link detector that searches for a specific substring.
struct SubstringLinkDetector: LinkDetector {
    var substring: String
    var callback: ((_ matchedString: String) -> Void)?
    
    init(substring: String, callback: ((_ matchedString: String) -> Void)? = nil) {
        self.substring = substring
        self.callback = callback
    }
    
    func detectLinks(in string: String) -> [Range<String.Index>] {
        var searchRange = string.characters.indices
        var ranges = [Range<String.Index>]()
        
        while let range = string.range(of: substring, options: [], range: searchRange, locale: nil) {
            searchRange = range.endIndex ..< string.endIndex
            ranges.append(range)
        }
        
        return ranges
    }
}
