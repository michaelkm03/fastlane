//
//  CreationFlowTypeHelper.swift
//  victorious
//
//  Created by Sharif Ahmed on 3/16/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation

@objc(VCreationFlowTypeHelper)
class CreationFlowTypeHelper: NSObject {
    
    fileprivate static let creationFlowTypes: [String : VCreationFlowType] = [
        "Create Image": .Image,
        "Create Video": .Video,
        "Create Poll": .Poll,
        "Create Text": .Text,
        "Create GIF": .GIF,
        "Create from Library": .Library,
        "Create from Mixed Media Camera": .MixedMediaCamera,
        "Create from Native Camera": .NativeCamera]
    
    static func creationFlowTypeForIdentifier(_ identifier: String) -> VCreationFlowType {
        return creationFlowTypes[identifier] ?? .Unknown
    }
}
