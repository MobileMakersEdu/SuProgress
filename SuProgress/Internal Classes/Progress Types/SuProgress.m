//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import "SuProgress.h"

@implementation SuProgress
@dynamic progress;

- (void)reset
{
    _properProgress = _trickled = 0.f;
    self.finished = NO;
}

- (void)trickle:(float)amount
{
    self.trickled += amount;
}

- (float)progress
{
    return (self.properProgress + self.trickled) / (1.0 + self.trickled);
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [super respondsToSelector:aSelector] ?: [self.endDelegate respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([self.endDelegate respondsToSelector:invocation.selector])
        [invocation invokeWithTarget:self.endDelegate];
}

- (id)endDelegate
{
    return nil;
}

@end