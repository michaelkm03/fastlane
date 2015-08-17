//
//  VStreamContentCellFactory.swift
//  victorious
//
//  Created by Sharif Ahmed on 7/24/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

import UIKit

/// Classes that conform to this protocol will receive messages about
/// stream items being selected from trending shelves.
@objc protocol VShelfStreamItemSelectionResponder : NSObjectProtocol {
    /// Sent when a stream item is selected from a trending shelf.
    ///
    /// :param: streamItem The selected stream item.
    /// :param: fromShelf The shelf that the stream item was selected from.
    func navigateTo(streamItem: VStreamItem?, fromShelf: VShelf)
}

//2.0 Improvement: Transform this into a protocol extension.

/// A cell factory for representing shelved streams across the app. Treat this as an
/// abstract base class and only use concrete subclasses to utilize this class's functionality.
/// In Swift 2.0 this class should be transformed into a protocol extension.
class VStreamContentCellFactory: NSObject, VHasManagedDependencies {
    
    private static let kTrendingShelfKey = "trendingShelf"
    
    /// The object that should recieve messages about marquee data and selection updates.
    weak var delegate: VStreamContentCellFactoryDelegate? {
        didSet {
            marqueeCellFactory.marqueeController?.setSelectionDelegate(delegate)
            marqueeCellFactory.marqueeController?.setDataDelegate(delegate)
        }
    }
    
    /// The cell factory that will provide marquee cells
    private let marqueeCellFactory: VMarqueeCellFactory
    
    private let trendingShelfFactory: VTrendingShelfCellFactory?
    
    /// The dependency manager used to style all cells from this factory
    private let dependencyManager: VDependencyManager
    
    /// Nil by default, overridden by subclasses to return a factory that provides non-shelf cells
    func defaultFactory() -> VStreamCellFactory? {
        return nil
    }

    required init(dependencyManager: VDependencyManager) {
        self.dependencyManager = dependencyManager
        marqueeCellFactory = VMarqueeCellFactory(dependencyManager: dependencyManager)
        trendingShelfFactory = dependencyManager.templateValueOfType(VTrendingShelfCellFactory.self, forKey: VStreamContentCellFactory.kTrendingShelfKey) as? VTrendingShelfCellFactory
    }
    
    private func factoryForStreamItem(streamItem: VStreamItem) -> VStreamCellFactory? {
        if let itemType = streamItem.itemType {
            switch itemType {
            case VStreamItemTypeMarquee:
                return marqueeCellFactory
            case VStreamItemTypeHashtag, VStreamItemTypeUser:
                return trendingShelfFactory
            default: ()
            }
        }
        return defaultFactory()
    }
}

extension VStreamContentCellFactory: VStreamCellFactory {
    
    func registerCellsWithCollectionView(collectionView: UICollectionView) {
        defaultFactory()?.registerCellsWithCollectionView(collectionView)
        marqueeCellFactory.registerCellsWithCollectionView(collectionView)
        trendingShelfFactory?.registerCellsWithCollectionView(collectionView)
    }
    
    func collectionView(collectionView: UICollectionView, cellForStreamItem streamItem: VStreamItem, atIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let factory = factoryForStreamItem(streamItem) {
            return factory.collectionView(collectionView, cellForStreamItem: streamItem, atIndexPath: indexPath)
        }
        assertionFailure("A cell was requested from a content cell factory with a nil default factory.")
        return UICollectionViewCell.new()
    }
    
    func sizeWithCollectionViewBounds(bounds: CGRect, ofCellForStreamItem streamItem: VStreamItem) -> CGSize {
        if let factory = factoryForStreamItem(streamItem) {
            return factory.sizeWithCollectionViewBounds(bounds, ofCellForStreamItem: streamItem)
        }
        return CGSize.zeroSize
    }
    
    func minimumLineSpacing() -> CGFloat {
        return 1
    }
    
    func sectionInsets() -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
}
