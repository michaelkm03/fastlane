//
//  ListMenuCommunityCollectionViewCell.swift
//  victorious
//
//  Created by Tian Lan on 4/19/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import UIKit

class ListMenuCommunityCollectionViewCell: UICollectionViewCell, ListMenuSectionCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    override var selected: Bool {
        didSet {
            updateCellBackgroundColor(to: contentView, selectedColor: dependencyManager.highlightedBackgroundColor, isSelected: selected)
        }
    }

    // MARK: - List Menu Section Cell
    
    var dependencyManager: VDependencyManager! {
        didSet {
            applyTemplateAppearance(with: dependencyManager)
        }
    }
    
    func configureCell(with community: ListMenuCommunityItem) {
        titleLabel.text = community.title
    }
    
    // MARK: - Private methods
    
    private func applyTemplateAppearance(with dependencyManager: VDependencyManager) {
        titleLabel.textColor = dependencyManager.titleColor
        titleLabel.font = dependencyManager.titleFont
    }
}

private extension VDependencyManager {
    
    var titleColor: UIColor? {
        return colorForKey("color.text.navItem")
    }
    
    var titleFont: UIFont? {
        return fontForKey("font.navigationItems")
    }
    
    var highlightedBackgroundColor: UIColor? {
        return colorForKey(VDependencyManagerAccentColorKey)
    }
}