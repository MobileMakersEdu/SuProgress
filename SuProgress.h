//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.

#import <UIKit/UIKit.h>


@interface UIViewController (SuProgress)

/** Welcome to our magic function. Any NSURLConnections
  * created in this block will all delegate messages
  * proxied via the ViewController's SuProgressBar so that
  * progress is automatically provided. Wonderful. */
/** NOTE currently this does not compare the thread ID, so
  * connections from multiple threads will proxy and we
  * are not trying to be thread safe so it may go all weird
  * on your ass. */
- (void)SuProgressURLConnectionsCreatedInBlock:(void(^)(void))block;

- (UIView *)SuProgressBar;

@end
