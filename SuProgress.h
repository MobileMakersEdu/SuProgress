//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.

#import <UIKit/UIKit.h>
@class AFHTTPRequestOperation;


@interface UIViewController (SuProgress)

/** Welcome to our magic function. Any NSURLConnections
  * created in this block will all delegate messages
  * proxied via the ViewController's SuProgressBar so that
  * progress is automatically provided. Wonderful. */
/** NOTE currently this does not compare the thread ID, so
  * connections from multiple threads will proxy and we
  * are not trying to be thread safe so it may go all weird
  * on you. */
- (void)SuProgressURLConnectionsCreatedInBlock:(void(^)(void))block;


/** Do this *after* you have set the UIWebView's delegate
  * we will then proxy delegate events as we need them too
  * TODO feel free to implement a swizzling way to do this
  * but please be sure to handle the whole state matrix.
  */
- (void)SuProgressForWebView:(UIWebView *)webView;

- (UIView *)SuProgressBar;

/** Not as convenient as for NSURLConnection, currently. We will
  * fix this soon.
  */
- (void)SuProgressForAFHTTPRequestOperation:(AFHTTPRequestOperation *)operation;

@end
