//
//  ImageAsset.swift
//  VictoriousIOSSDK
//
//  Created by Josh Hinman on 10/25/15.
//  Copyright © 2015 Victorious, Inc. All rights reserved.
//

import Foundation

/// A thumbnail, profile picture, or other image asset
public struct ImageAsset {
    public let mediaMetaData: MediaMetaData
    
    public init(mediaMetaData: MediaMetaData) {
        self.mediaMetaData = mediaMetaData
    }
}

extension ImageAsset {
    public init?(json: JSON) {
        guard let mediaMetaData = MediaMetaData(json: json, customUrlKeys: ["imageUrl", "image_url", "imageURL"]) else {
            return nil
        }
        self.mediaMetaData = mediaMetaData
    }
}
