//
//  VExploreViewController.swift
//  victorious
//
//  Created by Tian Lan on 8/18/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

import UIKit

/// Base view controller for the explore screen that gets
/// presented when "explore" button on the tab bar is tapped
class VExploreViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak private var searchBar: UISearchBar!
    @IBOutlet weak private var collectionView: UICollectionView!

    /// The dependencyManager that is used to manage dependencies of explore screen
    private(set) var dependencyManager: VDependencyManager?
    private let numberOfSectionsInCollectionView = 3
    
    /// MARK: - View Controller Initialization
    
    class func new( #dependencyManager: VDependencyManager ) -> VExploreViewController {
        let storyboard = UIStoryboard(name: "Explore", bundle: nil)
        if let exploreVC = storyboard.instantiateInitialViewController() as? VExploreViewController {
            exploreVC.dependencyManager = dependencyManager
            return exploreVC
        }
        fatalError("Failed to instantiate VExploreViewController with storyboard")
    }
    
    /// MARK: - View Controller LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.v_supplementaryHeaderView = searchBar
        self.automaticallyAdjustsScrollViewInsets = false;
        self.extendedLayoutIncludesOpaqueBars = true;
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    /// MARK: - UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numberOfRows = 0
        
        switch (section) {
        case 0:
            numberOfRows = 3
        case 1:
            numberOfRows = 3
        case 2:
            numberOfRows = 12
        default:
            fatalError("Unexpected number of sections in collection view")
        }
        
        return numberOfRows
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let placeHolderCell = collectionView.dequeueReusableCellWithReuseIdentifier("placeHolder", forIndexPath: indexPath) as? UICollectionViewCell {
            return placeHolderCell
        }
        fatalError("Could not find a cell for item!")
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return numberOfSectionsInCollectionView
    }
}
