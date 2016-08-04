//
//  ListMenuCreatorCollectionViewCell.swift
//  victorious
//
//  Created by Tian Lan on 4/21/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import UIKit

class ListMenuCreatorCollectionViewCell: UICollectionViewCell, ListMenuSectionCell {
    typealias Cell = ListMenuCreatorCollectionViewCell
    
    @IBOutlet private weak var avatarView: AvatarView!
    @IBOutlet private weak var creatorNameLabel: UILabel!
    
    override var selected: Bool {
        didSet {
            updateCellBackgroundColor(to: contentView, selectedColor: dependencyManager?.highlightedBackgroundColor, isSelected: selected)
        }
    }
    
    // MARK: - List Menu Section Cell
    
    var dependencyManager: VDependencyManager? {
        didSet {
            if let dependencyManager = dependencyManager {
                applyTemplateAppearance(with: dependencyManager)
            }
        }
    }
    
    func configureCell(with user: UserModel) {
        creatorNameLabel.text = user.displayName
        avatarView.user = user
    }
    
    // MARK: - Private methods
    
    private func applyTemplateAppearance(with dependencyManager: VDependencyManager) {
        creatorNameLabel.textColor = dependencyManager.titleColor
        creatorNameLabel.font = dependencyManager.titleFont
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
