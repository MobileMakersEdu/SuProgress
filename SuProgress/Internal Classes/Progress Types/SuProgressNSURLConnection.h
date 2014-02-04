//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import "SuProgress.h"

@interface SuProgressNSURLConnection : SuProgress <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
/**
 * Declared as strong because NSURLConnection treats its delegates as strong
 */
@property (strong, nonatomic) id<NSURLConnectionDelegate, NSURLConnectionDataDelegate> endDelegate;

@end
