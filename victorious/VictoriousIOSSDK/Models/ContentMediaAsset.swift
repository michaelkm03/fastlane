//
//  ContentMediaAsset.swift
//  victorious
//
//  Created by Vincent Ho on 5/10/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation

public enum ContentMediaAsset {
    case video(url: NSURL, source: String?)
    case youtube(remoteID: String, source: String?)
    case gif(url: NSURL, source: String?)
    case image(url: NSURL)
    
    init?(contentType: String, sourceType: String, json: JSON) {
        
        switch contentType {
        case "image":
            guard let url = json["data"].URL else {
                return nil
            }
            self = .image(url: url)
        case "video", "gif":
            var url: NSURL?
            
            switch sourceType {
            case "video_assets":
                url = json["data"].URL
            case "remote_assets":
                url = json["remote_content_url"].URL
            default:
                return nil
            }
            
            let source = json["source"].string
            let externalID = json["external_id"].string
            
            if contentType == "video" {
                if let source = source,
                    let externalID = externalID where source == "youtube" {
                    self = .youtube(remoteID: externalID, source: source)
                } else if let url = url {
                    self = .video(url: url, source: source)
                } else {
                    return nil
                }
            } else if contentType == "gif" {
                guard let url = url else {
                    return nil
                }
                self = .gif(url: url, source: source)
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    /// URL pointing to the resource.
    public var url: NSURL? {
        switch self {
        case .youtube(_, _):
            return nil
        case .video(let url, _):
            return url
        case .gif(let url, _):
            return url
        case .image(let url):
            return url
        }
    }
    
    /// String describing the source. May return "youtube", "giphy", or nil.
    public var source: String? {
        switch self {
        case .youtube(_, let source):
            return source
        case .video(_, let source):
            return source
        case .gif(_, let source):
            return source
        default:
            return nil
        }
    }
    
    /// String for the external ID
    public var externalID: String? {
        switch self {
        case .youtube(let externalID, _):
            return externalID
        default: return nil
        }
    }
    
    public var uniqueID: String {
        switch self {
        case .youtube(let externalID, _):
            return externalID
        case .video(let url, _):
            return url.absoluteString
        case .gif(let url, _):
            return url.absoluteString
        case .image(let url):
            return url.absoluteString
        }
    }
}