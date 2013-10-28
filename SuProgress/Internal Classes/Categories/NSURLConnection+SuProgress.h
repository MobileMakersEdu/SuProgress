//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import <Foundation/Foundation.h>

@interface NSURLConnection (SuProgress)

- (id)SuProgress_initWithRequest:(NSURLRequest *)request
                        delegate:(id)delegate
                startImmediately:(BOOL)startImmediately;

@end
