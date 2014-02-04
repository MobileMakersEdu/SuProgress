//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import "SuProgressNSURLConnection.h"
#import "NSURLConnection+SuProgress.h"
#import "UIViewController+SuProgress.h"
#import "SuProgressManager.h"
@implementation NSURLConnection (SuProgress)

// Annoyingly the unswizzled methods do not defer to one of these
// two so we must swizzle them both with near identical code.

// Our ogre acts as an NSURLConnectionDelegate proxy, and filters
// progress to our progress bar as its intermediary step.

#define SuNSURLConnectionOgreMacro \
SuProgressNSURLConnection *ogre = [SuProgressNSURLConnection new]; \
ogre.endDelegate = delegate; \
[SuProgressKing addOgre:ogre singleUse:YES]

- (id)SuProgress_initWithRequest:(NSURLRequest *)request
                        delegate:(id)delegate
                startImmediately:(BOOL)startImmediately
{
    SuProgressNSURLConnection *ogre = [SuProgressNSURLConnection new];
    ogre.endDelegate = delegate;
    [[SuProgressManager currentManager] addOgre:ogre singleUse:YES];
    
    return [self SuProgress_initWithRequest:request delegate:ogre startImmediately:startImmediately];
}

- (id)SuProgress_initWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
    SuProgressNSURLConnection *ogre = [SuProgressNSURLConnection new];
    
    ogre.endDelegate = delegate;
    [[SuProgressManager currentManager] addOgre:ogre singleUse:YES];
    
    return [self SuProgress_initWithRequest:request delegate:ogre];
}

@end
