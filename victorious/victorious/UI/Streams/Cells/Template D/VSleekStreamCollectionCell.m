//
//  VSleekStreamCollectionCell.m
//  victorious
//
//  Created by Sharif Ahmed on 3/13/15.
//  Copyright (c) 2015 Victorious. All rights reserved.
//

#import "VSleekStreamCollectionCell.h"
#import <CCHLinkTextView/CCHLinkTextViewDelegate.h>

#import "VSequence+Fetcher.h"
#import "VDependencyManager.h"
#import "VDependencyManager+VHighlightContainer.h"
#import "VSequencePreviewView.h"
#import "UIView+AutoLayout.h"
#import "NSString+VParseHelp.h"
#import "VSleekActionView.h"
#import "VHashTagTextView.h"
#import "VStreamHeaderTimeSince.h"
#import "VCompatibility.h"
#import "VSequenceCountsTextView.h"
#import "VSequenceExpressionsObserver.h"
#import "VCellSizeCollection.h"
#import "VCellSizingUserInfoKeys.h"
#import "VActionButtonAnimationController.h"
#import "VListicleView.h"
#import "VEditorializationItem.h"
#import "VStream.h"

// These values must match the constraint values in interface builder
static const CGFloat kSleekCellHeaderHeight = 50.0f;
static const CGFloat kSleekCellActionViewHeight = 48.0f;
static const CGFloat kCaptionToPreviewVerticalSpacing = 7.0f;
static const CGFloat kMaxCaptionTextViewHeight = 200.0f;
static const CGFloat kCountsTextViewMinHeight = 29.0f;
static const UIEdgeInsets kCaptionMargins = { 0.0f, 28.0f, 5.0f, 28.0f };
static const UIEdgeInsets kCaptionInsets = { 4.0, 0.0, 0.0, 4.0 };

@interface VSleekStreamCollectionCell () <VBackgroundContainer, CCHLinkTextViewDelegate, VSequenceCountsTextViewDelegate>

@property (nonatomic, strong) VSequencePreviewView *previewView;
@property (nonatomic, strong) VDependencyManager *dependencyManager;
@property (nonatomic, weak) IBOutlet UIView *previewContainer;
@property (nonatomic, weak) IBOutlet UIView *loadingBackgroundContainer;
@property (nonatomic, weak) IBOutlet VSleekActionView *sleekActionView;
@property (nonatomic, weak) IBOutlet VStreamHeaderTimeSince *headerView;
@property (nonatomic, weak) IBOutlet VHashTagTextView *captionTextView;
@property (nonatomic, weak ) IBOutlet NSLayoutConstraint *previewContainerHeightConstraint;
@property (nonatomic, weak ) IBOutlet NSLayoutConstraint *captionHeight;
@property (nonatomic, strong) UIView *dimmingContainer;
@property (nonatomic, strong) VSequenceExpressionsObserver *expressionsObserver;
@property (nonatomic, strong) VActionButtonAnimationController *actionButtonAnimationController;
@property (nonatomic, weak) IBOutlet VSequenceCountsTextView *countsTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *captiontoPreviewVerticalSpacing;
@property (nonatomic, strong) IBOutlet VListicleView *listicleView;
@property (nonatomic, readwrite) VStreamItem *streamItem;
@property (nonatomic, strong) VEditorializationItem *editorialization;

@end

@implementation VSleekStreamCollectionCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.previewContainer.clipsToBounds = YES;
    self.captionTextView.textContainerInset = kCaptionInsets;
    self.captionTextView.linkDelegate = self;
    [self setupDimmingContainer];
    
    self.countsTextView.textSelectionDelegate = self;
    self.actionButtonAnimationController = [[VActionButtonAnimationController alloc] init];
}

+ (VCellSizeCollection *)cellLayoutCollection
{
    static VCellSizeCollection *collection;
    if ( collection == nil )
    {
        collection = [[VCellSizeCollection alloc] init];
        [collection addComponentWithConstantSize:CGSizeMake( 0.0f, kSleekCellHeaderHeight)];
        [collection addComponentWithDynamicSize:^CGSize(CGSize size, NSDictionary *userInfo)
         {
             VSequence *sequence = userInfo[ kCellSizingSequenceKey ];
             CGFloat textHeight = 0.0f;
             if ( sequence.name.length > 0 )
             {
                 VDependencyManager *dependencyManager = userInfo[ kCellSizingDependencyManagerKey ];
                 NSDictionary *attributes = [self sequenceDescriptionAttributesWithDependencyManager:dependencyManager];
                 CGFloat textWidth = size.width - kCaptionMargins.left - kCaptionMargins.right;
                 textHeight = VCEIL( [sequence.name frameSizeForWidth:textWidth andAttributes:attributes].height );
                 textHeight += kCaptionInsets.top + kCaptionInsets.bottom;
             }
             return CGSizeMake( 0.0f, textHeight );
         }];
        [collection addComponentWithDynamicSize:^CGSize(CGSize size, NSDictionary *userInfo)
         {
            VSequence *sequence = userInfo[ kCellSizingSequenceKey ];
            return CGSizeMake( 0.0f, sequence.name.length > 0 ? kCaptionToPreviewVerticalSpacing : 0.0f );
         }];
        [collection addComponentWithDynamicSize:^CGSize(CGSize size, NSDictionary *userInfo)
         {
             VSequence *sequence = userInfo[ kCellSizingSequenceKey ];
             CGFloat previewHeight =  size.width  / [sequence previewAssetAspectRatio];
             return CGSizeMake( 0.0f, previewHeight );
         }];
        [collection addComponentWithConstantSize:CGSizeMake( 0.0f, kSleekCellActionViewHeight)];
        [collection addComponentWithDynamicSize:^CGSize(CGSize size, NSDictionary *userInfo)
         {
             CGFloat textWidth = size.width - kCaptionMargins.left - kCaptionMargins.right;
             VDependencyManager *dependencyManager = userInfo[ kCellSizingDependencyManagerKey ];
             NSDictionary *attributes = [[self class] sequenceCountsAttributesWithDependencyManager:dependencyManager];
             
             // FIXME: The use of "V" is just to get a good size for *something* in this text field since
             // we can't know what the actual text for the label is in a static method
             return CGSizeMake( 0.0f, MAX( kCountsTextViewMinHeight, [@"V" frameSizeForWidth:textWidth andAttributes:attributes].height ) );
         }];
        [collection addComponentWithConstantSize:CGSizeMake( 0.0f, kCaptionMargins.bottom)];
    }
    return collection;
}

#pragma mark - VSequenceCountsTextViewDelegate

- (void)likersTextSelected
{
    UIResponder<VSequenceActionsDelegate> *responder = [self targetForAction:@selector(willShowLikersForSequence:fromView:) withSender:self];
    NSAssert( responder != nil, @"We need an object in the responder chain for commenting or showing comments.");
    [responder willShowLikersForSequence:self.sequence fromView:self];
}

- (void)commentsTextSelected
{
    UIResponder<VSequenceActionsDelegate> *responder = [self targetForAction:@selector(willCommentOnSequence:fromView:) withSender:self];
    NSAssert( responder != nil, @"We need an object in the responder chain for showing likers.");
    [responder willCommentOnSequence:self.sequence fromView:self];
}

#pragma mark - VHasManagedDependencies

- (void)setStream:(VStream *)stream
{
    _stream = stream;
    [self updateListicleForSequence:self.sequence andStream:self.stream];
}

- (void)setDependencyManager:(VDependencyManager *)dependencyManager
{
    if (_dependencyManager == dependencyManager)
    {
        return;
    }
    _dependencyManager = dependencyManager;

    if ([self.previewView respondsToSelector:@selector(setDependencyManager:)])
    {
        [self.previewView setDependencyManager:self.dependencyManager];
    }
    if ([self.sleekActionView respondsToSelector:@selector(setDependencyManager:)])
    {
        [self.sleekActionView setDependencyManager:dependencyManager];
    }
    if ([self.headerView respondsToSelector:@selector(setDependencyManager:)])
    {
        [self.headerView setDependencyManager:dependencyManager];
    }
    if ([self.captionTextView respondsToSelector:@selector(setDependencyManager:)])
    {
        [self.captionTextView setDependencyManager:dependencyManager];
    }
    if ([self.listicleView respondsToSelector:@selector(setDependencyManager:)])
    {
        [self.listicleView setDependencyManager:dependencyManager];
    }
    
    [self.countsTextView setTextHighlightAttributes:[[self class] sequenceCountsActiveAttributesWithDependencyManager:dependencyManager]];
    [self.countsTextView setTextAttributes:[[self class] sequenceCountsAttributesWithDependencyManager:dependencyManager]];
}

+ (NSDictionary *)sequenceCountsActiveAttributesWithDependencyManager:(VDependencyManager *)dependencyManager
{
    UIFont *font = [dependencyManager fontForKey:VDependencyManagerLabel3FontKey];
    UIColor *textColor = [dependencyManager colorForKey:VDependencyManagerLinkColorKey];
    return @{ NSFontAttributeName: font, NSForegroundColorAttributeName: textColor };
}

+ (NSDictionary *)sequenceCountsAttributesWithDependencyManager:(VDependencyManager *)dependencyManager
{
    UIFont *font = [dependencyManager fontForKey:VDependencyManagerLabel3FontKey];
    UIColor *textColor = [dependencyManager colorForKey:VDependencyManagerContentTextColorKey];
    return @{ NSFontAttributeName: font, NSForegroundColorAttributeName: textColor };
}

#pragma mark - Property Accessors

- (void)setSequence:(VSequence *)sequence
{
    _sequence = sequence;
    
    [self updatePreviewViewForSequence:sequence];
    self.headerView.sequence = sequence;
    self.sleekActionView.sequence = sequence;
    [self updateCaptionViewForSequence:sequence];
    [self.previewContainer removeConstraint:self.previewContainerHeightConstraint];
    [self setNeedsUpdateConstraints];
    
    __weak typeof(self) welf = self;
    self.expressionsObserver = [[VSequenceExpressionsObserver alloc] init];
    [self.expressionsObserver startObservingWithSequence:sequence onUpdate:^
     {
         typeof(self) strongSelf = welf;
         [strongSelf updateCountsTextViewForSequence:sequence];
         [strongSelf.actionButtonAnimationController setButton:strongSelf.sleekActionView.likeButton
                                                      selected:sequence.isLikedByMainUser.boolValue];
         [strongSelf.actionButtonAnimationController setButton:strongSelf.sleekActionView.repostButton
                                                      selected:sequence.hasReposted.boolValue];
     }];
}

- (void)updateCountsTextViewForSequence:(VSequence *)sequence
{
    const BOOL canLike = [self.dependencyManager numberForKey:VDependencyManagerLikeButtonEnabledKey].boolValue;
        
    self.countsTextView.hideComments = !sequence.permissions.canComment;
    self.countsTextView.hideLikes = !canLike;
    [self.countsTextView setCommentsCount:sequence.commentCount.integerValue];
    [self.countsTextView setLikesCount:sequence.likeCount.integerValue];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    [self.dependencyManager setHighlighted:highlighted onHost:self];
}

#pragma mark - Internal Methods

- (void)setupDimmingContainer
{
    self.dimmingContainer = [UIView new];
    self.dimmingContainer.alpha = 0;
    self.dimmingContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.previewContainer addSubview:self.dimmingContainer];
    [self.previewContainer v_addFitToParentConstraintsToSubview:self.dimmingContainer];
}

- (void)updateConstraints
{
    // Add new height constraint for preview container to account for aspect ratio of preview asset
    CGFloat aspectRatio = [self.sequence previewAssetAspectRatio];
    NSLayoutConstraint *heightToWidth = [NSLayoutConstraint constraintWithItem:self.previewContainer
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.previewContainer
                                                                     attribute:NSLayoutAttributeWidth
                                                                    multiplier:(1 / aspectRatio)
                                                                      constant:0.0f];
    [self.previewContainer addConstraint:heightToWidth];
    self.previewContainerHeightConstraint = heightToWidth;
    
    [super updateConstraints];
}

- (void)updatePreviewViewForSequence:(VSequence *)sequence
{
    if ([self.previewView canHandleSequence:sequence])
    {
        [self.previewView setSequence:sequence];
        return;
    }
    
    [self.previewView removeFromSuperview];
    self.previewView = [VSequencePreviewView sequencePreviewViewWithSequence:sequence];
    [self.previewContainer insertSubview:self.previewView belowSubview:self.dimmingContainer];
    [self.previewContainer v_addFitToParentConstraintsToSubview:self.previewView];
    if ([self.previewView respondsToSelector:@selector(setDependencyManager:)])
    {
        [self.previewView setDependencyManager:self.dependencyManager];
    }
    [self.previewView setSequence:sequence];
}

- (void)updateCaptionViewForSequence:(VSequence *)sequence
{
    if ( sequence.name == nil || sequence.name.length == 0|| self.dependencyManager == nil)
    {
        self.captionTextView.attributedText = nil;
        self.captionHeight.constant = 0.0f;
        self.captiontoPreviewVerticalSpacing.constant = 0.0f;
    }
    else
    {
        self.captionTextView.attributedText = [[NSAttributedString alloc] initWithString:sequence.name
                                                                              attributes:[VSleekStreamCollectionCell sequenceDescriptionAttributesWithDependencyManager:self.dependencyManager]];
        self.captiontoPreviewVerticalSpacing.constant = kCaptionToPreviewVerticalSpacing;
        self.captionHeight.constant = kMaxCaptionTextViewHeight;
    }
    [self layoutIfNeeded];
}

- (void)updateListicleForSequence:(VSequence *)sequence andStream:(VStream *)stream
{
    // Headline depends on both the sequence AND the stream
    NSString *apiPath = stream.apiPath;
    self.editorialization = [sequence editorializationForStreamWithApiPath:apiPath];
    BOOL hasHeadline = self.editorialization.headline.length > 0;
    if (hasHeadline && (self.editorialization.headline != nil))
    {
        self.listicleView.hidden = NO;
        self.listicleView.headlineText = self.editorialization.headline;
    }
}

- (void)prepareForReuse
{
    self.listicleView.hidden = YES;
}

#pragma mark - VBackgroundContainer

- (UIView *)loadingBackgroundContainerView
{
    return self.loadingBackgroundContainer;
}

- (UIView *)backgroundContainerView
{
    return self.contentView;
}

#pragma mark - VStreamCellComponentSpecialization

+ (NSString *)reuseIdentifierForStreamItem:(VStreamItem *)streamItem
                            baseIdentifier:(NSString *)baseIdentifier
                         dependencyManager:(VDependencyManager *)dependencyManager
{
    NSString *identifier = baseIdentifier == nil ? [[NSString alloc] init] : baseIdentifier;
    identifier = [NSString stringWithFormat:@"%@.%@", identifier, NSStringFromClass(self)];
    if ( [streamItem isKindOfClass:[VSequence class]] )
    {
        identifier = [VSequencePreviewView reuseIdentifierForSequence:(VSequence *)streamItem
                                                       baseIdentifier:identifier
                                                    dependencyManager:dependencyManager];
    }
    
    return [VSleekActionView reuseIdentifierForStreamItem:streamItem
                                           baseIdentifier:identifier
                                        dependencyManager:dependencyManager];
}

#pragma mark - Class Methods

+ (NSDictionary *)sequenceDescriptionAttributesWithDependencyManager:(VDependencyManager *)dependencyManager
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    if ( dependencyManager != nil )
    {
        attributes[ NSFontAttributeName ] = [dependencyManager fontForKey:VDependencyManagerParagraphFontKey];
        attributes[ NSForegroundColorAttributeName ] = [dependencyManager colorForKey:VDependencyManagerMainTextColorKey];
    }
    attributes[ NSParagraphStyleAttributeName ] = [[NSMutableParagraphStyle alloc] init];
    return [NSDictionary dictionaryWithDictionary:attributes];
}

#pragma mark - Sizing

+ (CGSize)actualSizeWithCollectionViewBounds:(CGRect)bounds sequence:(VSequence *)sequence
                           dependencyManager:(VDependencyManager *)dependencyManager
{
    CGSize base = CGSizeMake( CGRectGetWidth(bounds), 0.0 );
    NSDictionary *userInfo = @{ kCellSizingSequenceKey : sequence,
                                VCellSizeCacheKey : sequence.name ?: @"",
                                kCellSizingDependencyManagerKey : dependencyManager };
    return [[[self class] cellLayoutCollection] totalSizeWithBaseSize:base userInfo:userInfo];
}

#pragma mark - VStreamCellFocus

- (void)setHasFocus:(BOOL)hasFocus
{
    if ([self.previewView conformsToProtocol:@protocol(VStreamCellFocus)])
    {
        [(id <VStreamCellFocus>)self.previewView setHasFocus:hasFocus];
    }
}

- (CGRect)contentArea
{
    return self.previewContainer.frame;
}

#pragma mark - CCHLinkTextViewDelegate

- (void)linkTextView:(CCHLinkTextView *)linkTextView didTapLinkWithValue:(id)value
{
    UIResponder<VSequenceActionsDelegate> *targetForHashTagSelection = [self targetForAction:@selector(hashTag:tappedFromSequence:fromView:)
                                                                                  withSender:self];
    if (targetForHashTagSelection == nil)
    {
        NSAssert(false, @"We need an object in the responder chain for hash tag selection.!");
    }
    [targetForHashTagSelection hashTag:value
                    tappedFromSequence:self.sequence
                              fromView:self];
}

#pragma mark - VHighlightContainer

- (UIView *)highlightContainerView
{
    return self.dimmingContainer;
}

- (UIView *)highlightActionView
{
    return self.dimmingContainer;
}

#pragma mark - VStreamCellTracking

- (VSequence *)sequenceToTrack
{
    return self.sequence;
}

@end
