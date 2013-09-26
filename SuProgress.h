//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.

#import <UIKit/UIKit.h>


@interface SuProgress : NSObject
@end


@interface UINavigationBar (SuProgress)

// Totally sucks to have to do it this way rather than just pull in an
// NSURLConnection. Also, since we don't want to hog the delegate, we'll have to
// proxy it anyway with swizzling, so overall, we'll maybe be able to do better
- (SuProgress *)followURLConnectionWithRequest:(NSURLConnection *)urlConnection;

@end
