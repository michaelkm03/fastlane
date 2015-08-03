//
//  VTrimmerViewController.h
//  victorious
//
//  Created by Michael Sena on 12/30/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VHasManagedDependencies.h"

@import CoreMedia;

@class VTrimmerViewController;

/**
 *  A Data source for the thumbnail timeline.
 */
@protocol VTrimmerThumbnailDataSource <NSObject>
/**
 *  Requets the data source for a thumbnail at the specified time.
 */
- (void)trimmerViewController:(VTrimmerViewController *)trimmer
             thumbnailForTime:(CMTime)time
                  withSuccess:(void (^)(UIImage *thumbnail, CMTime timeForImage, id generatingDataSource))success
                  withFailure:(void (^)(NSError *error))errorBlock;

@end

/**
 *  Notifies a delegate about specific events.
 */
@protocol VTrimmerViewControllerDelegate <NSObject>

@optional
/**
 *  Called whenever a new time range is selected.
 */
- (void)trimmerViewController:(VTrimmerViewController *)trimmerViewController
   didUpdateSelectedTimeRange:(CMTimeRange)selectedTimeRange;

/**
 *  Called whenever the user begins scrolling and current play time is out of the selected time range.
 *  It would be a good idea to pause any players and immediately attempt to seek to the specified time to give the user a good seek experience.
 */
- (void)trimmerViewControllerBeganSeeking:(VTrimmerViewController *)trimmerViewController
                                   toTime:(CMTime)time;

/**
 *  Called whenever the timeline comes to a rest.
 */
- (void)trimmerViewControllerEndedSeeking:(VTrimmerViewController *)trimmerViewController;

@end

/**
 *  A ViewController that manages seeking and trimming for an individual timeline.
 */
@interface VTrimmerViewController : UIViewController <VHasManagedDependencies>

/**
 *  Yes if the trimmer is currently changing the trim range 
 *  (due to scrolling or tracking of the user's touches).
 */
@property (nonatomic, readonly) BOOL isInteracting;

/**
 *  The minimum start time.
 */
@property (nonatomic, assign) CMTime minimumStartTime;

/**
 *  The maximum end time.
 */
@property (nonatomic, assign) CMTime maximumEndTime;

/**
 *  The maximum trim duration.
 */
@property (nonatomic, assign) CMTime maximumTrimDuration;

/**
 *  The current play time. This updates the progress bar indicating playback over the thumbnail timeline.
 */
@property (nonatomic, assign) CMTime currentPlayTime;

/**
 *  The currently selected time range reflecting the users seek + trim intent.
 */
@property (nonatomic, readonly) CMTimeRange selectedTimeRange;

/**
 *  A Delegate for notifiyng of important events.
 */
@property (nonatomic, weak) id <VTrimmerViewControllerDelegate> delegate;

/**
 *  A thumbnail data source.
 */
@property (nonatomic, weak) id <VTrimmerThumbnailDataSource> thumbnailDataSource;

/**
 Initializes a new instance of VTrimmerViewController with an instance of VDependencyManager
 */
- (instancetype)initWithDependencyManager:(VDependencyManager *)dependencyManager NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end
