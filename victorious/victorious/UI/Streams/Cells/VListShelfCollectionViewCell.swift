//
//  VListShelfCollectionViewCell.swift
//  victorious
//
//  Created by Sharif Ahmed on 8/14/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

import UIKit

class VListShelfCollectionViewCell: VBaseCollectionViewCell {
    
    struct Constants {
        static let separatorHeight: CGFloat = 4
        static let minimumTopVerticalSpace: CGFloat = 11
        static let minimumTitleToDetailVerticalSpace: CGFloat = 5
        static let detailToCollectionViewVerticalSpace: CGFloat = 12
        
        static let contentHorizontalInset: CGFloat = 18
        
        static let interCellSpace: CGFloat = 4
        static let collectionViewSectionEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 11, bottom: 11, right: 11)
    }

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet var minimumTitleToTopConstraints: [NSLayoutConstraint]!
    @IBOutlet var horizontalEdgeConstraints: [NSLayoutConstraint]!
    @IBOutlet var minimumTitleToDetailSpaceConstraints: [NSLayoutConstraint]!
    @IBOutlet weak var detailToCollectionViewSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
        
    var shelf: VShelf? {
        didSet {
            self.onShelfSet()
        }
    }
    
    var dependencyManager : VDependencyManager? {
        didSet {
            self.onDependencyManagerSet()
        }
    }
    
    private var centeringInset: CGFloat = 0
    private var cellSideLength: CGFloat = 0
    private var expandedCellSideLength: CGFloat {
        return cellSideLength * 2 + Constants.interCellSpace
    }

    /// Override in subclasses to make adjustments based on the dependency manager
    func onDependencyManagerSet() {
        if let dependencyManager = dependencyManager {
            dependencyManager.addBackgroundToBackgroundHost(self)
        }
    }
    
    /// Override in subclasses to make adjustments based on the shelf
    func onShelfSet() {
        if let streamItems = shelf?.stream?.streamItems {
            if let streamItems = streamItems.array as? [VStreamItem] {
                for (index, streamItem) in enumerate(streamItems) {
                    collectionView.registerClass(VShelfContentCollectionViewCell.self, forCellWithReuseIdentifier: VShelfContentCollectionViewCell.reuseIdentifierForStreamItem(streamItem, baseIdentifier: nil, dependencyManager: dependencyManager))
                }
            }
        }
        collectionView.reloadData()
        
        detailLabel.text = shelf?.name
    }
    
    override var bounds : CGRect {
        didSet {
            updateCollectionViewSize()
        }
    }
    
    private func updateCollectionViewSize() {
        let totalWidths = VListShelfCollectionViewCell.totalCellWidths(collectionView.bounds.width)
        cellSideLength = VListShelfCollectionViewCell.cellSideLength(totalWidths)
        centeringInset = floor(totalWidths % cellSideLength)
        collectionViewHeightConstraint.constant = VListShelfCollectionViewCell.collectionViewHeight(cellSideLength: cellSideLength)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private class func totalCellWidths(collectionViewWidth: CGFloat) -> CGFloat {
        let sectionInset = Constants.collectionViewSectionEdgeInsets
        var totalCellWidths = collectionViewWidth - sectionInset.left - sectionInset.right - (Constants.interCellSpace * 4)
        return totalCellWidths
    }
    
    private class func cellSideLength(totalCellWidths: CGFloat) -> CGFloat {
        return floor(totalCellWidths / 5)
    }
    
    private class func collectionViewHeight(cellSideLength length: CGFloat) -> CGFloat {
        let collectionViewSectionEdgeInsets = Constants.collectionViewSectionEdgeInsets
        return length * 2 + Constants.interCellSpace + collectionViewSectionEdgeInsets.top + collectionViewSectionEdgeInsets.bottom
    }
    
    class func desiredSize(collectionViewBounds: CGRect, shelf:VShelf, dependencyManager: VDependencyManager) -> CGSize {
        let width = collectionViewBounds.width
        let length = cellSideLength(totalCellWidths(width))
        let collectionViewSectionEdgeInsets = Constants.collectionViewSectionEdgeInsets
        let collectionViewHeight = self.collectionViewHeight(cellSideLength: length)
        let height = Constants.separatorHeight + Constants.minimumTopVerticalSpace + Constants.minimumTitleToDetailVerticalSpace + collectionViewHeight
        return CGSizeMake(width, height)
    }
    
    //MARK: - View management
    
    override func awakeFromNib() {
        super.awakeFromNib()
        for constraint in minimumTitleToTopConstraints {
            constraint.constant = Constants.minimumTopVerticalSpace
        }
        for constraint in horizontalEdgeConstraints {
            constraint.constant = Constants.contentHorizontalInset
        }
        for constraint in minimumTitleToDetailSpaceConstraints {
            constraint.constant = Constants.minimumTitleToDetailVerticalSpace
        }
        separatorHeightConstraint.constant = Constants.separatorHeight
        detailToCollectionViewSpaceConstraint.constant = Constants.detailToCollectionViewVerticalSpace
        updateCollectionViewSize()
    }
}

extension VListShelfCollectionViewCell : UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        var insets = Constants.collectionViewSectionEdgeInsets
        insets.right += centeringInset
        insets.left += centeringInset
        return insets
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return Constants.interCellSpace
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return Constants.interCellSpace
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var side = cellSideLength
        if indexPath.row == 0 {
            side = expandedCellSideLength
        }
        return CGSizeMake(side, side)
    }
    
}

extension VListShelfCollectionViewCell: VBackgroundContainer {
    
    func backgroundContainerView() -> UIView! {
        return contentView
    }
    
}
