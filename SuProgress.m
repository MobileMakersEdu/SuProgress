//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.

#import "SuProgress.h"
#define SuProgressBarTag 51381
#define SuProgressBarHeight 2


@interface SuProgress ()
@property (nonatomic) float progress;
@property (weak, nonatomic) UINavigationBar *navbar;
@end

@interface SuprNSURLConnection : SuProgress <NSURLConnectionDelegate>
@end


//TODO manage application network spinner too (make optional)


@implementation UINavigationBar (SuProgress)

- (NSURLConnection *)followURLConnectionWithRequest:(NSURLRequest *)request
{
    UIView *bar = [self viewWithTag:SuProgressBarTag];
    if (!bar) {
        CGSize sz = self.bounds.size;
        bar = [[UIView alloc] initWithFrame:(CGRect){0, sz.height - SuProgressBarHeight, 0, SuProgressBarHeight}];
        bar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        bar.backgroundColor = self.window.tintColor;
        bar.tag = SuProgressBarTag;
        [self addSubview:bar];
    } else {
        //TODO if we already exist and are already following something then follow both by slowing
        // future progress, or if too far along, whizz to end and then restart
        return nil;
    }

    SuProgress *ogre = [SuprNSURLConnection new];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:ogre];
    ogre.navbar = self;

    if (connection)
        ogre.progress = 0.1;

    return connection;
}

@end



@implementation SuProgress {
    NSDate *startTime;
    NSDate *lastIncrementTime;
    NSDate *waitAtLeastUntil;
}

- (id)init {
    startTime = [NSDate date];
    return self;
}

- (void)setProgress:(float)progress {
    if (progress < _progress) {
        NSLog(@"Won't set progress to %f as it's less than current value (%f)", progress, _progress);
        return;
    }
    _progress = progress;

    UIView *bar = [_navbar viewWithTag:SuProgressBarTag];
    CGSize sz = _navbar.bounds.size;

    NSTimeInterval duration = 0.3;
    NSTimeInterval delay = lastIncrementTime ? MAX(0.01, [[NSDate date] timeIntervalSinceDate:lastIncrementTime]) : 0;

    [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        bar.frame = (CGRect){0, sz.height - SuProgressBarHeight, sz.width * progress, SuProgressBarHeight};
    } completion:nil];

    waitAtLeastUntil = [NSDate dateWithTimeIntervalSinceNow:delay + duration];
    lastIncrementTime = [NSDate date];

    //TODO if progress is greater than or equal to one fade out, but if progress is set again within a time
    // period come back, OR have a hard-done method… probably depends. With NSURLConnection, we can do that
    // but in general it may lead to bugs in how people use it, while also going with >= 1 may be the same.
}

- (void)finish {
    UIView *bar = [_navbar viewWithTag:SuProgressBarTag];

    NSTimeInterval finishFillDuration = MIN(0.15, (bar.bounds.size.width / _navbar.bounds.size.width) * 0.3);

    [UIView animateWithDuration:finishFillDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        // if we are already filled, then CoreAnimation is smart and this
        // block will finish instantly
        bar.frame = (CGRect){0, bar.frame.origin.y, CGSizeMake(_navbar.bounds.size.width, SuProgressBarHeight)};
    }
    completion:^(BOOL finished) {
        NSTimeInterval dt = [[NSDate date] timeIntervalSinceDate:startTime];
        NSTimeInterval dt2 = [waitAtLeastUntil timeIntervalSinceNow];
        NSTimeInterval delay = dt2 < 0 ? -dt2 : MAX(0, 1. - dt);

        [UIView animateWithDuration:0.4 delay:delay  options:0 animations:^{
            bar.alpha = 0;
        } completion:^(BOOL finished) {
            [bar removeFromSuperview];
        }];
    }];
}

@end



@implementation SuprNSURLConnection {
    long long total;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)rsp {
    if (rsp.statusCode == 200) {
        total = [rsp.allHeaderFields[@"Content-Length"] intValue];
        self.progress = 0.2;
        NSLog(@"%@", [rsp allHeaderFields]);

        if ([rsp.allHeaderFields[@"Content-Encoding"] isEqual:@"gzip"]) {
            // Oh man, we get the data back UNgzip'd, and the total figure is
            // for bytes of content to expect! So we'll guestimate and x4 it
            // FIXME anyway to get a better solution? Probably not without private API
            // or AFNetworking.
            total *= 4;
        }
        //TODO no length provided, do drips
    } else {
        //TODO error!
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // TODO should it become larger than the expectedSize we should progress in much smaller increments
    self.progress += 0.7f * ((float)data.length / (float)(total));
    // Broadcast a notification with the progress change, or call a delegate
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    //TODO red
    self.progress = 1;
}

- (void)connectionDidFinishLoading:(id)connection {
    [self finish];
}

@end

