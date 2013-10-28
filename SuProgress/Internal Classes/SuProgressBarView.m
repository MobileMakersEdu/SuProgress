//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import "SuProgressBarView.h"

NSInteger const kSuProgressBarHeight             = 2;

@interface SuProgressBarView ()

@property SuProgressBarViewState state;
@property NSDate *startTime;
@property NSDate *waitAtLeastUntil;

@end

@implementation SuProgressBarView
- (id)init
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _manager = [SuProgressManager managerWithDelegate:self];
    }
    
    return self;
}

- (void)dealloc
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)finished
{
    self.state = SuProgressBarViewFinishing;
    
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         // if we are already filled, then CoreAnimation is smart and this
                         // block will finish instantly
                         self.frame = (CGRect){0, self.frame.origin.y, self.superview.bounds.size.width, kSuProgressBarHeight};
                     } completion:^(BOOL finished) {
                         if (!finished)
                             return;
                         
                         NSTimeInterval dt = [[NSDate date] timeIntervalSinceDate:self.startTime];
                         NSTimeInterval dt2 = [self.waitAtLeastUntil timeIntervalSinceNow];
                         NSTimeInterval delay = dt2 < 0 ? -dt2 : MAX(0, 1. - dt);
                         
                         [UIView animateWithDuration:0.4 delay:delay options:0 animations:^{
                             self.alpha = 0;
                         } completion:^(BOOL finished) {
                             if (finished)
                                 self.frame = (CGRect){self.frame.origin, 0, self.frame.size.height};
                         }];
                         
                         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                     }];
}

- (void)progressed:(float)progress {
    if (self.state == SuProgressBarViewFinishing) {
        // finishing animation is happening. We are going to just override
        // that, then in finishing animation completion handler we will notice
        // and stop finishing
        self.state = SuProgressBarViewReady;
    }
    
    if (self.state == SuProgressBarViewReady) {
        
        self.startTime = [NSDate date];
        self.waitAtLeastUntil = nil;
        self.state = SuProgressBarViewProgressing;
        
        self.frame = (CGRect){self.frame.origin, 0, self.frame.size.height};
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    CGSize sz = self.superview.bounds.size;
    NSTimeInterval duration = 0.3;
    int opts = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseIn;
    [UIView animateWithDuration:duration delay:0 options:opts animations:^{
        self.alpha = 1;
        self.frame = (CGRect){self.frame.origin, sz.width * progress, kSuProgressBarHeight};
    } completion:nil];
    
    self.waitAtLeastUntil = [NSDate dateWithTimeIntervalSinceNow:duration];
}

- (float)progress {
    return self.manager.progress;
}

@end
