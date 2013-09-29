//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#define SuProgressBarTag 51381
#define SuProgressBarHeight 2

@protocol SuProgressDelegate
- (void)started:(id)ogre;
- (void)ogre:(id)ogre progressed:(float)progress;
- (void)finished:(id)ogre;
@end

@interface SuProgressBarView : UIView <SuProgressDelegate>
@property (nonatomic, strong) NSMutableArray *ogres;
@property (nonatomic) float progress;
@end

@interface NSURLConnection (SuProgress)
- (id)SuProgress_initWithRequest:(NSURLRequest *)request delegate:(id)delegate;
@end

@interface SuProgress : NSObject  // probably NSProgress right?
@property (nonatomic, weak) id<SuProgressDelegate> delegate;
@property (nonatomic) float progress;
@property (nonatomic) BOOL started;
@property (nonatomic) BOOL finished;
@end

// this class acts as an NSURLConnectionDelegate proxy
@interface SuProgressNSURLConnection : SuProgress <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
// strong because NSURLConnection treats its delegates as strong
@property (strong, nonatomic) id<NSURLConnectionDelegate, NSURLConnectionDataDelegate> endDelegate;
@end

@interface SuProgressUIWebView : SuProgress <UIWebViewDelegate>
@property (strong, nonatomic) UIWebView *webView;
@end



// Used inside SuProgressURLConnectionsCreatedInBlock
// making us not-thread safe, but otherwise fine
// yes globals are horrible, but in this case there
// wasn't another solution I could think of that
// wasn't also ugly AND way more code.
static UIViewController *SuProgressViewController;



@implementation UIViewController (SuProgress)

- (void)SuProgressURLConnectionsCreatedInBlock:(void(^)(void))block {
    Class class = [NSURLConnection class];
    Method original = class_getInstanceMethod(class, @selector(initWithRequest:delegate:));
    Method swizzle = class_getInstanceMethod(class, @selector(SuProgress_initWithRequest:delegate:));

    SuProgressViewController = self;
    
    method_exchangeImplementations(original, swizzle);
    block();
    method_exchangeImplementations(swizzle, original);  // put it back
}

- (SuProgressBarView *)SuProgressBar {
    if (self.navigationController && self.navigationController.navigationBar) {
        UINavigationBar *navbar = self.navigationController.navigationBar;
        UIView *bar = [navbar viewWithTag:SuProgressBarTag];
        if (!bar) {
            CGSize sz = navbar.bounds.size;
            bar = [[SuProgressBarView alloc] initWithFrame:(CGRect){0, sz.height - SuProgressBarHeight, 0, SuProgressBarHeight}];
            bar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
            bar.backgroundColor = navbar.window.tintColor;
            bar.tag = SuProgressBarTag;
            [navbar addSubview:bar];
        }
        return (id)bar;
    } else {
        NSLog(@"Sorry dude, I haven't written code that supports showing progress in this configuration yet! Fork and help?");
        return nil;
    }
}

- (void)SuProgressForWebView:(UIWebView *)webView {
    SuProgressUIWebView *ogre = [SuProgressUIWebView new];
    ogre.delegate = [self SuProgressBar];
    ogre.webView = webView;  // have to unset delegate because it isn't weak :P
    [[self SuProgressBar].ogres addObject:ogre];
    webView.delegate = ogre;
}

@end



@implementation SuProgressBarView {
    NSDate *startTime;
    NSDate *lastIncrementTime;
    NSDate *waitAtLeastUntil;
    
    // We trickle a little when jobs start to indicate
    // progress and trickle ocassionally to indicate that
    // stuff is still happening, so the actual portion of
    // the width that is available for actual progress is
    // less than one.
    float progressPortion;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        startTime = [NSDate date];
        progressPortion = 0.9;
        _ogres = [NSMutableArray new];
        self.progress = 0.05;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    return self;
}

- (void)started:(SuProgress *)ogre {
    if (_progress == 0.05f) {
        // do an initial trickle, once
        self.progress = 0.1;
        progressPortion = 0.8;
    }
}

- (void)ogre:(SuProgress *)ogre progressed:(float)progress {
    // TODO should reported progress go > 1 we should still drip,
    // but in tiny amounts since we will then exceed 90%
    
    float remaining_progress = 0;
    for (id ogre in _ogres)
        remaining_progress += 1.f - [ogre progress];

    // seems complicated, and… it is, this way to calculate
    // actual progress allows us to accept new jobs some
    // time after other jobs were already started
    // NOTE only works because this delegate method is called
    // before the ogre's progress property is incremented
    self.progress += (progress / remaining_progress) * progressPortion;
}

- (void)setProgress:(float)progress {
    if (progress < _progress) {
        NSLog(@"Won't set progress to %f as it's less than current value (%f)", progress, _progress);
        return;
    }
    _progress = progress;

    UIView *bar = self;
    CGSize sz = self.superview.bounds.size;

    NSTimeInterval duration = 0.3;
    NSTimeInterval delay = lastIncrementTime ? MAX(0.01, [[NSDate date] timeIntervalSinceDate:lastIncrementTime]) : 0;

    [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        bar.frame = (CGRect){bar.frame.origin, sz.width * progress, SuProgressBarHeight};
    } completion:nil];

    waitAtLeastUntil = [NSDate dateWithTimeIntervalSinceNow:delay + duration];
    lastIncrementTime = [NSDate date];

    //TODO if progress is greater than or equal to one fade out, but if progress is set again within a time
    // period come back, OR have a hard-done method… probably depends. With NSURLConnection, we can do that
    // but in general it may lead to bugs in how people use it, while also going with >= 1 may be the same.
}

- (BOOL)allOgresFinished {
    for (id ogre in _ogres)
        if (![ogre finished])
            return NO;
    return YES;
}

- (void)finished:(SuProgress *)ogre {
    if (!self.allOgresFinished)
        return;

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        // if we are already filled, then CoreAnimation is smart and this
        // block will finish instantly
        self.frame = (CGRect){0, self.frame.origin.y, self.superview.bounds.size.width, SuProgressBarHeight};
    }
    completion:^(BOOL finished) {
        NSTimeInterval dt = [[NSDate date] timeIntervalSinceDate:startTime];
        NSTimeInterval dt2 = [waitAtLeastUntil timeIntervalSinceNow];
        NSTimeInterval delay = dt2 < 0 ? -dt2 : MAX(0, 1. - dt);

        [UIView animateWithDuration:0.4 delay:delay  options:0 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }];
}

@end



@implementation SuProgress
// FIXME bit dumb to allow setting started to false considering
// this is an invalid state in fact. Same for finished. Needs enum.
- (void)setStarted:(BOOL)started {
    _started = started;
    if (started) {
        [_delegate started:self];
    }
}
- (void)setFinished:(BOOL)finished {
    _finished = finished;
    if (finished) {
        _progress = 1;
        [_delegate finished:self];
    }
}
@end



@implementation SuProgressNSURLConnection {
    long long total_bytes;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)rsp {
    if (rsp.statusCode == 200) {
        total_bytes = [rsp.allHeaderFields[@"Content-Length"] intValue];
        if ([rsp.allHeaderFields[@"Content-Encoding"] isEqual:@"gzip"]) {
            // Oh man, we get the data back UNgzip'd, and the total figure is
            // for bytes of content to expect! So we'll guestimate and x4 it
            // FIXME anyway to get a better solution? Probably not without private API
            // or AFNetworking.
            total_bytes *= 4;
        }
    } else {
        //TODO error!
    }
    self.started = YES;
    
    if ([_endDelegate respondsToSelector:@selector(connection:didReceiveResponse:)])
        [_endDelegate connection:connection didReceiveResponse:rsp];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    float f = total_bytes
            ? (float)data.length / (float)(total_bytes)
            // we can't know how big the content is TODO but we
            // could start adding a lot and get smaller as we
            // guess the rate and amounts a little
            : 0.01;
    [self.delegate ogre:self progressed:f];
    self.progress += f;

    if ([_endDelegate respondsToSelector:@selector(connection:didReceiveData:)])
        [_endDelegate connection:connection didReceiveData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.finished = YES;
    if ([_endDelegate respondsToSelector:@selector(connection:didFailWithError:)])
        [_endDelegate connection:connection didFailWithError:error];
}

- (void)connectionDidFinishLoading:(id)connection {
    self.finished = YES;
    if ([_endDelegate respondsToSelector:@selector(connectionDidFinishLoading:)])
        [_endDelegate connectionDidFinishLoading:connection];
}

@end




@implementation NSURLConnection (Debug)

- (id)SuProgress_initWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
    // Our ogre acts as an NSURLConnectionDelegate proxy, and filters
    // progress to our progress bar as its intermediary step.
    SuProgressNSURLConnection *ogre = [SuProgressNSURLConnection new];
    ogre.delegate = [SuProgressViewController SuProgressBar];
    ogre.endDelegate = delegate;
    [[SuProgressViewController SuProgressBar].ogres addObject:ogre];

    // looks weird? Google: objectivec swizzling
    return [self SuProgress_initWithRequest:request delegate:ogre];
}

@end




// Inspired by: https://github.com/ninjinkun/NJKWebViewProgress

#define SuProgressUIWebViewCompleteRPCURL "webviewprogressproxy:///complete"

@implementation SuProgressUIWebView {
    NSUInteger _loadingCount;
    NSUInteger _maxLoadCount;
    NSURL *_currentURL;
    BOOL _interactive;
}

- (void)setFinished:(BOOL)finished {
    if (finished) {
        _webView.delegate = nil;
    }
    [super setFinished:finished];
}

- (void)incrementProgress {
    float progress = self.progress;
    float maxProgress = _interactive ? 1.f : 0.5f;
    float remainPercent = (float)_loadingCount / (float)_maxLoadCount;
    float increment = (maxProgress - progress) * remainPercent;

    [self.delegate ogre:self progressed:increment];
    self.progress += increment;
}

- (void)reset {
    _maxLoadCount = _loadingCount = 0;
    _interactive = NO;
    self.progress = 0.0;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.absoluteString isEqualToString:@SuProgressUIWebViewCompleteRPCURL]) {
        self.finished = YES;
        return NO;
    }
    
    BOOL isFragmentJump = NO;
    if (request.URL.fragment) {
        NSString *nonFragmentURL = [request.URL.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:request.URL.fragment] withString:@""];
        isFragmentJump = [nonFragmentURL isEqualToString:webView.request.URL.absoluteString];
    }
    
    BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];
    
    BOOL isHTTP = [request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"];
    if (!isFragmentJump && isHTTP && isTopLevelNavigation) {
        _currentURL = request.URL;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    _loadingCount++;
    _maxLoadCount = fmax(_maxLoadCount, _loadingCount);
    
    self.started = YES;
    [self.delegate started:self];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _loadingCount--;
    [self incrementProgress];
    
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    
    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {
        _interactive = YES;
        // this callsback on webView:shouldStartLoadWithRequest:navigationType
        // when it has finished executing, indicating to us that loading has
        // completed (sorta, images usually still flicker in)
        [webView stringByEvaluatingJavaScriptFromString:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '" SuProgressUIWebViewCompleteRPCURL "'; document.body.appendChild(iframe);  }, false);"];
    }
    
    BOOL isNotRedirect = [_currentURL isEqual:webView.request.mainDocumentURL];
    BOOL complete = [readyState isEqualToString:@"complete"];
    if (complete && isNotRedirect) {
        self.finished = YES;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self webViewDidFinishLoad:webView];
}

@end
