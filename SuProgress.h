//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.

#import <UIKit/UIKit.h>


@interface UIViewController (SuProgress)

// TODO add delegate paramater
// NOTE it sucks that we can't just accept a urlConnection here. But
// they don't allow us to change the delegate after creation. Probably
// though we can do some obj-c magic to proxy the delegate via us, so TODO that
- (NSURLConnection *)SuProgressForRequest:(NSURLRequest *)request;

- (UIView *)SuProgressBar;

@end
