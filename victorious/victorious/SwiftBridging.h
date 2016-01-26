//
//  SwiftBridging.h
//  victorious
//
//  Created by Patrick Lynch on 4/13/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

/**
 Use this file to import Objective-C headers that need to be exposed to any Swift code.
 */

#import "CHTCollectionViewWaterfallLayout+ColumnAccessor.h"
#import "ColorSpaceConversion.h"
#import "DiscoverSearchViewController.h"
#import "INVector3.h"
#import "NSDate+timeSince.h"
#import "NSString+VCrypto.h"
#import "NSString+VParseHelp.h"
#import "NSURL+MediaType.h"
#import "NSURL+VDataCacheID.h"
#import "UIColor+VBrightness.h"
#import "UIColor+VHex.h"
#import "UIImage+ImageCreation.h"
#import "UIImage+Resize.h"
#import "UIImage+VTint.h"
#import "UIImageView+Blurring.h"
#import "UIImageView+VLoadingAnimations.h"
#import "UIStoryboard+VMainStoryboard.h"
#import "UIView+AutoLayout.h"
#import "UIViewController+VLayoutInsets.h"
#import "UIViewController+VRootNavigationController.h"
#import "VAbstractFilter.h"
#import "VAbstractMarqueeCollectionViewCell.h"
#import "VAbstractMarqueeController.h"
#import "VAbstractStreamCollectionViewController.h"
#import "VActionItem.h"
#import "VAnswer+Fetcher.h"
#import "VAnswer.h"
#import "VAppTimingEventType.h"
#import "VApplicationTracking.h"
#import "VAsset+Fetcher.h"
#import "VAsset+RestKit.h"
#import "VAuthorizationContext.h"
#import "VAutomation.h"
#import "VBackgroundContainer.h"
#import "VBadgeImageType.h"
#import "VBaseCollectionViewCell.h"
#import "VBaseVideoSequencePreviewView.h"
#import "VButton.h"
#import "VCaptureContainerViewController.h"
#import "VChangePasswordViewController.h"
#import "VCoachmarkManager.h"
#import "VCollectionViewCommentHighlighter.h"
#import "VCollectionViewStreamFocusHelper.h"
#import "VColorType.h"
#import "VComment+Fetcher.h"
#import "VComment.h"
#import "VCommentAlertHelper.h"
#import "VCommentCellUtilitiesController.h"
#import "VCommentCellUtilitiesDelegate.h"
#import "VCommentMediaType.h"
#import "VCommentTextAndMediaView.h"
#import "VCommentsUtilityButtonConfiguration.h"
#import "VCompatibility.h"
#import "VContentCell.h"
#import "VContentCommentsCell.h"
#import "VContentDeepLinkHandler.h"
#import "VContentViewFactory.h"
#import "VContentViewOriginViewController.h"
#import "VConversation.h"
#import "VConversationCell.h"
#import "VConversationContainerViewController.h"
#import "VConversationListViewController.h"
#import "VConversationViewController.h"
#import "VCreatePollViewController.h"
#import "VCreateSheetViewController.h"
#import "VDataCache.h"
#import "VDefaultProfileButton.h"
#import "VDefaultProfileImageView.h"
#import "VDependencyManager+VAccessoryScreens.h"
#import "VDependencyManager+VBackgroundContainer.h"
#import "VDependencyManager+VCoachmarkManager.h"
#import "VDependencyManager+VNavigationMenuItem.h"
#import "VDependencyManager+VObjectManager.h"
#import "VDependencyManager+VTabScaffoldViewController.h"
#import "VDependencyManager+VTracking.h"
#import "VDependencyManager+VUserProfile.h"
#import "VDependencyManager.h"
#import "VDirectoryCellFactory.h"
#import "VDirectoryCellUpdateableFactory.h"
#import "VDirectoryCollectionFlowLayout.h"
#import "VDirectoryCollectionViewController.h"
#import "VDiscoverContainerViewController.h"
#import "VEditCommentViewController.h"
#import "VEditableTextPostViewController.h"
#import "VElapsedTimeFormatter.h"
#import "VEnvironment.h"
#import "VEnvironmentManager.h"
#import "VExploreMarqueeCollectionViewFlowLayout.h"
#import "VExploreSearchResultsViewController.h"
#import "VFindContactsTableViewController.h"
#import "VFirstTimeInstallHelper.h"
#import "VFlaggedContent.h"
#import "VFocusable.h"
#import "VFollowControl.h"
#import "VFollowSource.h"
#import "VFollowedHashtag.h"
#import "VFollowedUser.h"
#import "VFooterActivityIndicatorView.h"
#import "VHasManagedDependencies.h"
#import "VHashTag.h"
#import "VHashTagTextView.h"
#import "VHashTags.h"
#import "VHashtag.h"
#import "VHashtagFollowingTableViewController.h"
#import "VHashtagSelectionResponder.h"
#import "VHashtagStreamCollectionViewController.h"
#import "VImageAsset.h"
#import "VImageAssetFinder+PollAssets.h"
#import "VImageAssetFinder.h"
#import "VImageLightboxViewController.h"
#import "VImageSequencePreviewView.h"
#import "VInlineSearchTableViewController.h"
#import "VInsetMarqueeCollectionViewCell.h"
#import "VInsetMarqueeController.h"
#import "VInsetMarqueeStreamItemCell.h"
#import "VInteraction.h"
#import "VKeyboardBarViewController.h"
#import "VKeyboardInputAccessoryView.h"
#import "VLargeNumberFormatter.h"
#import "VLaunchScreenProvider.h"
#import "VLightboxTransitioningDelegate.h"
#import "VLightweightContentViewController.h"
#import "VLinearGradientView.h"
#import "VListicleView.h"
#import "VLoadingViewController.h"
#import "VLoginFlowAPIHelper.h"
#import "VLoginFlowControllerDelegate.h"
#import "VLoginRegistrationFlow.h"
#import "VLoginType.h"
#import "VMarqueeController.h"
#import "VMediaAttachment.h"
#import "VMediaAttachmentPresenter.h"
#import "VMessage+Fetcher.h"
#import "VMessage.h"
#import "VMessageCell.h"
#import "VModernLoginAndRegistrationFlowViewController.h"
#import "VNavigationController.h"
#import "VNavigationMenuItem.h"
#import "VNoContentCollectionViewCellFactory.h"
#import "VNoContentView.h"
#import "VNode+Fetcher.h"
#import "VNotification.h"
#import "VNotificationCell.h"
#import "VNotificationSettings.h"
#import "VNotificationSettingsStateManager.h"
#import "VNotificationSettingsViewController.h"
#import "VNotificationsViewController.h"
#import "VObjectManager+ContentCreation.h"
#import "VObjectManager+Discover.h"
#import "VObjectManager+Login.h"
#import "VObjectManager+Pagination.h"
#import "VObjectManager+Private.h"
#import "VObjectManager+Sequence.h"
#import "VObjectManager.h"
#import "VPageType.h"
#import "VPaginationManager.h"
#import "VPhotoFilter.h"
#import "VPollResult.h"
#import "VPrivacyPoliciesViewController.h"
#import "VProfileCreateViewController.h"
#import "VProfileEditViewController.h"
#import "VPublishParameters.h"
#import "VPushNotificationManager.h"
#import "VReachability.h"
#import "VReposterTableViewController.h"
#import "VRootViewController.h"
#import "VSEquence.h"
#import "VScrollPaginator.h"
#import "VSequence+Fetcher.h"
#import "VSequence.h"
#import "VSequenceLiker.h"
#import "VSequencePermissions.h"
#import "VSequencePreviewView.h"
#import "VSessionTimer.h"
#import "VSettingsSwitchCell.h"
#import "VSettingsViewController.h"
#import "VSimpleModalTransition.h"
#import "VSleekStreamCellFactory.h"
#import "VStoredLogin.h"
#import "VStoredPassword.h"
#import "VStream+Fetcher.h"
#import "VStream+RestKit.h"
#import "VStreamCellFactory.h"
#import "VStreamCellSpecialization.h"
#import "VStreamCollectionViewController.h"
#import "VStreamContentCellFactoryDelegate.h"
#import "VStreamItem+Fetcher.h"
#import "VStreamItemPreviewView.h"
#import "VSuggestedUsersDataSource.h"
#import "VSwipeView.h"
#import "VTOSViewController.h"
#import "VTabScaffoldViewController.h"
#import "VTag.h"
#import "VTagSensitiveTextView.h"
#import "VTagSensitiveTextViewDelegate.h"
#import "VTagStringFormatter.h"
#import "VTemplateDecorator.h"
#import "VTextAndMediaView.h"
#import "VTextColorTool.h"
#import "VTextPostTextView.h"
#import "VTextSequencePreviewView.h"
#import "VTextToolController.h"
#import "VThemeManager.h"
#import "VTickerPickerViewController.h"
#import "VTimerManager.h"
#import "VTracking.h"
#import "VTrackingManager.h"
#import "VTransitionDelegate.h"
#import "VTrendingTagCell.h"
#import "VTwitterManager.h"
#import "VUploadTaskCreator.h"
#import "VUploadTaskInformation.h"
#import "VUser+RestKit.h"
#import "VUser.h"
#import "VUserProfileViewController.h"
#import "VUserTag.h"
#import "VUserTaggingTextStorage.h"
#import "VUserTaggingTextStorageDelegate.h"
#import "VUsersDataSource.h"
#import "VUtilityButtonCell.h"
#import "VVideoLightboxViewController.h"
#import "VVideoSequencePreviewView.h"
#import "VVideoView.h"
#import "VWebContentViewController.h"
#import "VWorkspaceShimDestination.h"
#import "VNewContentViewController.h"
