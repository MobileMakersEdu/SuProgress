//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol SuProgressDelegate <NSObject>

- (void)progressed:(id)ogre;

@end


@interface SuProgress : NSObject
/**
 *  Trickles are more indeterminate amounts of progress
 *  we calculate the overall progres from trickled and
 *  the real known progress above. Most progress types
 *  trickle at some point, eg. to indicate connection
 *  accepted
 */
@property CGFloat trickled;

@property (nonatomic, readonly) CGFloat progress;

@property (weak) id<SuProgressDelegate> delegate;

@property CGFloat properProgress;
@property BOOL finished;

- (void)reset;


@end
