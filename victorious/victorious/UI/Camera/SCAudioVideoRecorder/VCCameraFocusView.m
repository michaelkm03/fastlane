//
//  VCCameraFocusView
//

#import "VCCameraFocusView.h"
#import "VCCameraFocusTargetView.h"

#define BASE_FOCUS_TARGET_WIDTH 60
#define BASE_FOCUS_TARGET_HEIGHT 60

////////////////////////////////////////////////////////////
// PRIVATE DEFINITION
/////////////////////

@interface VCCameraFocusView()
{
    CGPoint _currentFocusPoint;
}

@property (strong, nonatomic) VCCameraFocusTargetView *cameraFocusTargetView;

@end

////////////////////////////////////////////////////////////
// IMPLEMENTATION
/////////////////////

@implementation VCCameraFocusView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    _currentFocusPoint = CGPointMake(0.5, 0.5);
    self.cameraFocusTargetView = [[VCCameraFocusTargetView alloc] init];
    self.cameraFocusTargetView.hidden = YES;
    [self addSubview:self.cameraFocusTargetView];
    
    self.focusTargetSize = CGSizeMake(BASE_FOCUS_TARGET_WIDTH, BASE_FOCUS_TARGET_HEIGHT);
    
    // Add a single tap gesture to focus on the point tapped, then lock focus
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
    [singleTap setNumberOfTapsRequired:1];
    [self addGestureRecognizer:singleTap];

    // Desactivating this as this heavily slow down the focus process
//    // Add a double tap gesture to reset the focus mode to continuous auto focus
//    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
//    [doubleTap setNumberOfTapsRequired:2];
//    [singleTap requireGestureRecognizerToFail:doubleTap];
//    [self addGestureRecognizer:doubleTap];
}

- (void)showFocusAnimation
{
    self.cameraFocusTargetView.hidden = NO;
    [self.cameraFocusTargetView startTargeting];
}

- (void)hideFocusAnimation
{
    [self.cameraFocusTargetView stopTargeting];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self adjustFocusView];
}

- (void)adjustFocusView
{
    self.cameraFocusTargetView.center = CGPointMake(self.frame.size.width * _currentFocusPoint.x, self.frame.size.height * _currentFocusPoint.y);
}

// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.camera.isFocusSupported)
    {
        CGPoint tapPoint = [gestureRecognizer locationInView:self];
        CGPoint convertedFocusPoint = [self.camera convertToPointOfInterestFromViewCoordinates:tapPoint];
        self.cameraFocusTargetView.center = tapPoint;
        [self.camera autoFocusAtPoint:convertedFocusPoint];
        _currentFocusPoint = convertedFocusPoint;
    }
}

// Change to continuous auto focus. The camera will constantly focus at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.camera.isFocusSupported)
    {
        self.cameraFocusTargetView.center = self.center;
        [self.camera continuousFocusAtPoint:CGPointMake(.5f, .5f)];
    }
}

- (void)setFocusTargetSize:(CGSize)focusTargetSize
{
    CGRect rect = self.cameraFocusTargetView.frame;
    rect.size = focusTargetSize;
    self.cameraFocusTargetView.frame = rect;
    [self adjustFocusView];
}

- (CGSize)focusTargetSize
{
    return self.cameraFocusTargetView.frame.size;
}

- (UIImage *)outsideFocusTargetImage
{
    return self.cameraFocusTargetView.outsideFocusTargetImage;
}

- (void)setOutsideFocusTargetImage:(UIImage *)outsideFocusTargetImage
{
    self.cameraFocusTargetView.outsideFocusTargetImage = outsideFocusTargetImage;
}

- (UIImage *)insideFocusTargetImage
{
    return self.cameraFocusTargetView.insideFocusTargetImage;
}

- (void)setInsideFocusTargetImage:(UIImage *)insideFocusTargetImage
{
    self.cameraFocusTargetView.insideFocusTargetImage = insideFocusTargetImage;
}

@end
