//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import <UIKit/UIKit.h>
#import "SuProgressManager.h"

FOUNDATION_EXPORT NSInteger const kSuProgressBarHeight;


/**
 *  This is enum handles the state of the SuProgressBars currently in play
 */
typedef NS_ENUM(NSUInteger, SuProgressBarViewState) {
    /**
     *  Ready to go
     */
    SuProgressBarViewReady,
    /**
     *  Ongoing progress
     */
    SuProgressBarViewProgressing,
    /**
     *  Wrapping up
     */
    SuProgressBarViewFinishing
};

@interface SuProgressBarView : UIView <SuProgressManagerDelegate>

@property (nonatomic, strong, readonly) SuProgressManager *manager;
@property (nonatomic, readonly) CGFloat progress;

@end