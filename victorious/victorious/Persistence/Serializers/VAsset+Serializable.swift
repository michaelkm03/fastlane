//
//  VAsset+Serializable.swift
//  victorious
//
//  Created by Patrick Lynch on 11/6/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

extension VAsset: DataStoreObject {}

extension VAsset: Serializable {
    
    public func serialize( asset: Asset, dataStore: DataStore ) {
        audioMuted              = asset.audioMuted
        backgroundColor         = asset.backgroundColor
        backgroundImageUrl      = asset.backgroundImageUrl
        data                    = asset.data
        duration                = asset.duration
        loop                    = asset.loop
        mimeType                = asset.mimeType?.rawValue
        playerControlsDisabled  = asset.playerControlsDisabled
        remoteContentId         = asset.remoteContentId
        remoteId                = Int(asset.assetId)
        remotePlayback          = asset.remotePlayback
        remoteSource            = asset.remoteSource
        speed                   = asset.speed
        streamAutoplay          = asset.streamAutoplay
        type                    = asset.type.rawValue
    }
}
