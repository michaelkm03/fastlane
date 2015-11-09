//
//  StreamItemType.swift
//  victorious
//
//  Created by Patrick Lynch on 11/6/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation

public enum StreamContentType: String {
    case Sequence       = "sequence"
    case Stream         = "stream"
    case Shelf          = "shelf"
    case Feed           = "feed"
    case Explore        = "explore"
    case Marquee        = "marquee"
    case User           = "user"
    case Hashtag        = "hashtag"
    case TrendingTopic  = "trendingTopic"
    case Playlist       = "playlist"
    case Recent         = "recent"
    case Image          = "image"
    case Video          = "video"
    case Gif            = "gif"
    case Poll           = "poll"
    case Text           = "text"
    case Content        = "content"
}

public protocol StreamItemType {
    var remoteID: String { get }
    var previewImagesObject: AnyObject? { get }
    var previewTextPostAsset: String? { get }
    var streamContentType: StreamContentType? { get }
    var itemType: StreamContentType? { get }
    var itemSubType: StreamContentType? { get }
    var previewImageAssets: [ImageAsset] { get }
    var streams: [Stream] { get }
}