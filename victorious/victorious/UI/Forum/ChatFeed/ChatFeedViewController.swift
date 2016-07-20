//
//  ChatFeedViewController.swift
//  victorious
//
//  Created by Patrick Lynch on 2/19/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import UIKit

class ChatFeedViewController: UIViewController, ChatFeed, ChatFeedDataSourceDelegate, UICollectionViewDelegateFlowLayout, VScrollPaginatorDelegate, NewItemsControllerDelegate, ChatFeedMessageCellDelegate {
    private struct Layout {
        private static let bottomMargin: CGFloat = 20.0
        private static let topMargin: CGFloat = 64.0
    }
    
    private var edgeInsets = UIEdgeInsets(top: Layout.topMargin, left: 0.0, bottom: Layout.bottomMargin, right: 0.0)
    
    private lazy var dataSource: ChatFeedDataSource = {
        return ChatFeedDataSource(dependencyManager: self.dependencyManager)
    }()
    
    private lazy var focusHelper: VCollectionViewStreamFocusHelper = {
        return VCollectionViewStreamFocusHelper(collectionView: self.collectionView)
    }()
    
    private let scrollPaginator = VScrollPaginator()
    
    // Used to create a temporary window where immediate re-stashing is disabled after unstashing
    private var canStashNewItems: Bool = true
    
    @IBOutlet private var collectionViewBottom: NSLayoutConstraint!
    
    // MARK: - ChatFeed
    
    weak var delegate: ChatFeedDelegate?
    var dependencyManager: VDependencyManager!
    
    @IBOutlet private(set) weak var collectionView: UICollectionView!
    @IBOutlet private(set) var newItemsController: NewItemsController?
    
    var chatInterfaceDataSource: ChatInterfaceDataSource {
        return dataSource
    }
    
    func setTopInset(value: CGFloat) {
        edgeInsets.top = value + Layout.topMargin
    }
    
    func setBottomInset(value: CGFloat) {
        collectionViewBottom.constant = value
        collectionView.superview?.layoutIfNeeded()
    }
    
    // MARK: - ForumEventReceiver
        
    var childEventReceivers: [ForumEventReceiver] {
        return [dataSource]
    }
    
    // MARK: - ForumEventSender
    
    weak var nextSender: ForumEventSender?
    
    // MARK: - NewItemsControllerDelegate
        
    func onNewItemsSelected() {
        dataSource.unstash()
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = .None
        extendedLayoutIncludesOpaqueBars = true
        automaticallyAdjustsScrollViewInsets = false
        
        dataSource.delegate = self
        dataSource.registerCells(for: collectionView)
        
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        
        scrollPaginator.delegate = self
        
        dataSource.nextSender = self
        
        newItemsController?.dependencyManager = dependencyManager
        newItemsController?.delegate = self
        newItemsController?.hide(animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dataSource.unstash()
        focusHelper.updateFocus()
        startTimestampUpdate()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        dataSource.stashingEnabled = true
        focusHelper.endFocusOnAllCells()
        stopTimestampUpdate()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let messageCell = cell as! ChatFeedMessageCell
        messageCell.delegate = self
        messageCell.startDisplaying()
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        (cell as! ChatFeedMessageCell).stopDisplaying()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return dataSource.collectionView(collectionView, sizeForItemAtIndexPath: indexPath)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return edgeInsets
    }
    
    // MARK: - ChatFeedDataSourceDelegate
    
    func chatFeedDataSource(dataSource: ChatFeedDataSource, didLoadItems newItems: [ChatFeedContent], loadingType: PaginatedLoadingType) {
        let removedPendingContentIndices = removePendingContent(newItems, loadingType: loadingType)
        handleNewItems(newItems, loadingType: loadingType, removedPendingContentIndices: removedPendingContentIndices)
    }
    
    func chatFeedDataSource(dataSource: ChatFeedDataSource, didStashItems stashedItems: [ChatFeedContent]) {
        let itemsContainOtherUserMessage = stashedItems.contains { !$0.content.wasCreatedByCurrentUser }
        
        if itemsContainOtherUserMessage {
            // Update stash count and show stash counter.
            newItemsController?.count = dataSource.stashedItems.count
            newItemsController?.show()
        }
    }
    
    func chatFeedDataSource(dataSource: ChatFeedDataSource, didUnstashItems unstashedItems: [ChatFeedContent]) {
        newItemsController?.hide()
        
        let removedPendingContentIndices = removePendingContent(unstashedItems, loadingType: .newer)
        
        handleNewItems(unstashedItems, loadingType: .newer, removedPendingContentIndices: removedPendingContentIndices) { [weak self] in
            if self?.collectionView.v_isScrolledToBottom == false {
                self?.collectionView.v_scrollToBottomAnimated(true)
            }
        }
    }
    
    var chatFeedItemWidth: CGFloat {
        return collectionView.bounds.width
    }
    
    func pendingItems(for chatFeedDataSource: ChatFeedDataSource) -> [ChatFeedContent] {
        return delegate?.publisher(for: self)?.pendingItems ?? []
    }
    
    private func removePendingContent(contentToRemove: [ChatFeedContent], loadingType: PaginatedLoadingType) -> [Int] {
        guard let publisher = delegate?.publisher(for: self) where loadingType == .newer else {
            return []
        }
        
        return publisher.remove(contentToRemove)
    }
    
    // MARK: - VScrollPaginatorDelegate
    
    func shouldLoadPreviousPage() {
        send(.loadOldContent)
    }
    
    // MARK: - ChatFeedMessageCellDelegate
    
    func messageCellDidSelectAvatarImage(messageCell: ChatFeedMessageCell) {
        guard let userID = messageCell.chatFeedContent?.content.author.id else {
            return
        }
        
        delegate?.chatFeed(self, didSelectUserWithUserID: userID)
    }
    
    func messageCellDidSelectMedia(messageCell: ChatFeedMessageCell) {
        guard let content = messageCell.chatFeedContent else {
            return
        }
        
        delegate?.chatFeed(self, didSelectContent: content)
    }
    
    func messageCellDidSelectFailureButton(messageCell: ChatFeedMessageCell) {
        guard let content = messageCell.chatFeedContent else {
            return
        }
        
        delegate?.chatFeed(self, didSelectFailureButtonForContent: content)
    }
    
    // MARK: - UIScrollViewDelegate
    
    var unstashingViaScrollingIsEnabled = true
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollPaginator.scrollViewDidScroll(scrollView)
        
        if scrollView.v_isScrolledToBottom {
            if unstashingViaScrollingIsEnabled {
                dataSource.unstash()
            }
            
            dataSource.stashingEnabled = false
        }
        else {
            dataSource.stashingEnabled = true
        }
        
        focusHelper.updateFocus()
        
        delegate?.chatFeed(self, didScroll: scrollView)
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        delegate?.chatFeed(self, willBeginDragging: scrollView)
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.chatFeed(self, willEndDragging: scrollView, withVelocity: velocity)
    }
    
    // MARK: - Timestamp update timer
    
    static let timestampUpdateInterval: NSTimeInterval = 1.0
    
    private var timerManager: VTimerManager?
    
    private func stopTimestampUpdate() {
        timerManager?.invalidate()
        timerManager = nil
    }
    
    private func startTimestampUpdate() {
        guard timerManager == nil else {
            return
        }
        
        timerManager = VTimerManager.addTimerManagerWithTimeInterval(
            ChatFeedViewController.timestampUpdateInterval,
            target: self,
            selector: #selector(onTimerTick),
            userInfo: nil,
            repeats: true,
            toRunLoop: NSRunLoop.mainRunLoop(),
            withRunMode: NSRunLoopCommonModes
        )
        
        onTimerTick()
    }
    
    private dynamic func onTimerTick() {
        dataSource.updateTimestamps(in: collectionView)
    }
}
