//
//  GIFSearchViewController+Layout.swift
//  victorious
//
//  Created by Patrick Lynch on 7/9/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

import UIKit

extension GIFSearchViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let section = self.searchDataSource.sections[ indexPath.section ]
        if let cell = collectionView.cellForItemAtIndexPath( indexPath ) as? GIFSearchCell {
            
            if section.isFullSize {
                cell.selected = false
            }
            else if self.selectedIndexPath == indexPath {
                self.hideFullSize( forItemAtIndexPath: indexPath )
                self.selectedIndexPath = nil
            }
            else {
                self.showFullSize( forItemAtIndexPath: indexPath )
                self.selectedIndexPath = indexPath
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let insets = (self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? UIEdgeInsets()
        let totalWidth = self.collectionView.bounds.width - insets.left - insets.right
        let totalHeight = self.collectionView.bounds.height - insets.top - insets.bottom
        let totalSize = CGSize(width: totalWidth, height: totalHeight )
        
        if self.searchDataSource.sections.count == 0 {
            return CGSize(width: totalSize.width, height: GIFSearchViewController.noContentCellHeight)
        }
        else {
            let section = self.searchDataSource.sections[ indexPath.section ]
            if section.count == 1 {
                return section.displaySize(withinSize: totalSize)
            }
            else {
                let displaySizes = section.displaySizes( withinSize: totalSize )
                return displaySizes[ indexPath.row ]
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: section == 0 ? GIFSearchViewController.headerViewHeight : 0.0 )
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let margin = GIFSearchViewController.defaultSectionMargin
        var insets = UIEdgeInsets(top: 0.0, left: margin, bottom: 0.0, right: margin)
        if section == self.searchDataSource.sections.count-1 {
            insets.bottom = GIFSearchViewController.defaultSectionMargin
        }
        return insets
    }
}

// Provides some size calculation methods to be used when determine sizes for cells in a collection view
private extension GIFSearchDataSource.Section {
    
    func displaySize( withinSize totalSize: CGSize ) -> CGSize {
        let gif = self.results[0]
        let maxHeight = totalSize.height - GIFSearchDataSource.Section.minMargin * 2.0
        return CGSize(width: totalSize.width, height: min(totalSize.width / gif.aspectRatio, maxHeight) )
    }
    
    func displaySizes( withinSize totalSize: CGSize ) -> [CGSize] {
        assert( self.results.count == 2, "This method only calculates sizes for sections with exactly 2 results" )
        
        var output = [CGSize](count: self.results.count, repeatedValue: CGSize.zeroSize)
        
        let gifA = self.results[0]
        let gifB = self.results[1]
        
        var sizeA = gifA.assetSize
        var sizeB = gifB.assetSize
        
        let hRatioA = sizeA.height / sizeB.height
        let hRatioB = sizeB.height / sizeA.height
        
        if hRatioA >= 1.0 {
            sizeB.width /= hRatioB
            sizeB.height /= hRatioB
        }
        else if hRatioB >= 1.0 {
            sizeA.width /= hRatioA
            sizeA.height /= hRatioA
        }
        
        let ratioA = sizeA.width / (sizeA.width + sizeB.width)
        let widthA = floor( totalSize.width * ratioA )
        output[0] = CGSize(width: widthA, height: widthA / gifA.aspectRatio )
        
        let ratioB = sizeB.width / (sizeA.width + sizeB.width)
        let widthB = floor( totalSize.width * ratioB )
        output[1] = CGSize(width: widthB, height: widthB / gifB.aspectRatio )
        
        return output
    }
}