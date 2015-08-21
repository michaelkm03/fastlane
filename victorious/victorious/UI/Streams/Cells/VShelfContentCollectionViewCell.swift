//
//  VShelfContentCollectionViewCell.swift
//  victorious
//
//  Created by Sharif Ahmed on 7/24/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

import UIKit

/// A simple UICollectionViewCell with a loading background and a preview view
/// for displaying the content of any provided stream item.
class VShelfContentCollectionViewCell: VBaseCollectionViewCell {
    
    private static let kTextPostBackgroundColorKey = "color.standard.textPost"

    /// The view that will house the preview view.
    let previewViewContainer = UIView()
    private var previewView: VStreamItemPreviewView = VImageSequencePreviewView()
    
    /// The stream item whose content will populate this cell.
    var streamItem: VStreamItem? {
        didSet {
            if streamItem == oldValue {
                return
            }
            
            let isTextPost = streamItem?.itemSubType == VStreamItemSubTypeText
            let shouldUpdateForTextPost = isTextPost && previewView.conformsToProtocol(VImagePreviewView.self)
            if previewView.canHandleStreamItem(streamItem) || shouldUpdateForTextPost {
                updatePreviewView(streamItem)
                return
            }
            previewView.removeFromSuperview()
            
            previewView = VStreamItemPreviewView(streamItem: streamItem)
            previewView.dependencyManager = dependencyManager
            
            if isTextPost {
                previewView = VImageSequencePreviewView(frame: CGRect.zeroRect)
            }
            
            updatePreviewView(streamItem)
        }
    }
    
    private func updatePreviewView(streamItem: VStreamItem?) {
        if let dependencyManager = previewView.dependencyManager {
            if streamItem?.itemSubType != VStreamItemSubTypeText {
                previewView.streamItem = streamItem
            }
            else if let imagePreviewView = previewView as? VImagePreviewView {
                imagePreviewView.previewImageView().image = UIImage(named: "createTextIcon")
                imagePreviewView.previewImageView().contentMode = UIViewContentMode.Center
                imagePreviewView.makeBackgroundContainerViewVisible(true)
                previewView.backgroundColor = dependencyManager.textPostBackgroundColor
            }
            if previewView.superview == nil {
                previewViewContainer.addSubview(previewView)
                v_addFitToParentConstraintsToSubview(previewView)
            }
        }
    }
    
    /// The dependency manager whose colors and fonts will be used to style this cell.
    var dependencyManager: VDependencyManager? {
        didSet {
            if let dependencyManager = dependencyManager {
                dependencyManager.addLoadingBackgroundToBackgroundHost(self)
                let needsUpdate = previewView.dependencyManager == nil
                previewView.dependencyManager = dependencyManager
                if needsUpdate {
                    updatePreviewView(streamItem)
                }
            }
        }
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        previewViewContainer.backgroundColor = UIColor.clearColor()
        contentView.addSubview(previewViewContainer)
        contentView.v_addFitToParentConstraintsToSubview(previewViewContainer)
    }
    
}

extension VShelfContentCollectionViewCell: VStreamCellComponentSpecialization {
    
    class func reuseIdentifierForStreamItem(streamItem: VStreamItem, baseIdentifier: String?, dependencyManager: VDependencyManager?) -> String {
        var updatedIdentifier = identifier(baseIdentifier, className: NSStringFromClass(self))
        
        if let itemType = streamItem.itemType {
            updatedIdentifier += itemType
        }
        
        if let itemSubType = streamItem.itemSubType {
            updatedIdentifier += "." + itemSubType
        }
        
        return updatedIdentifier
    }
    
    /// The suggested identifier based on the provided baseIdentifier and class name.
    ///
    /// :param: baseIdentifier The existing identifier, if present.
    /// :param: className The string representation of the current class or another unique identifier.
    ///
    /// :return: A string based on the provided inputs.
    static func identifier(baseIdentifier: String?, className: String) -> String {
        var updatedIdentifier = className
        if let existingIdentifier = baseIdentifier {
            updatedIdentifier = existingIdentifier
        }
        updatedIdentifier += "."
        return updatedIdentifier
    }
    
}

extension VShelfContentCollectionViewCell: VBackgroundContainer {
    
    func loadingBackgroundContainerView() -> UIView! {
        return previewViewContainer
    }
    
}

private extension VDependencyManager {
    
    var textPostBackgroundColor: UIColor {
        return colorForKey(VShelfContentCollectionViewCell.kTextPostBackgroundColorKey)
    }
    
}
