//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#define SuProgressBarTag 51381
#define SuProgressBarHeight 2

@protocol SuProgressDelegate <NSObject>
- (void)ogred:(id)ogre;
@end

@protocol KingOfDelegates <NSObject>
- (void)progressed:(float)progress;
- (void)finished;
@end

@interface NSURLConnection (SuProgress)
- (id)SuProgress_initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately;
@end

@interface SuProgress : NSObject {
    float properProgress;

    // trickles are more indeterminate amounts of progress
    // we calculate the overall progres from trickled and
    // the real known progress above. Most progress types
    // trickle at some point, eg. to indicate connection
    // accepted
    float trickled;

    BOOL finished;
}
@property (nonatomic, readonly) float progress;
@property (nonatomic, readonly) BOOL finished;
@property (nonatomic, weak) id<SuProgressDelegate> delegate;
- (void)reset;
- (id)endDelegate;
@end

@interface TheKingOfOgres : NSObject <SuProgressDelegate>
+ (id)kingWithDelegate:(id<KingOfDelegates>)delegate;
- (void)addOgre:(SuProgress *)ogre singleUse:(BOOL)singleUse;
@property (nonatomic, readonly) NSMutableArray *ogres;
@property (nonatomic, weak, readonly) id<KingOfDelegates> delegate;
@property (nonatomic, readonly) float progress;
@end

@interface SuProgressBarView : UIView <KingOfDelegates>
@property (nonatomic, readonly) float progress;
@property (nonatomic, strong, readonly) TheKingOfOgres *king;
@end



//TODO make each bar a sublayer (or subview for easier animation control)
//     because if new progress occurs during fadeout it should let old bar
//     fadeout still, and new bar should start over the top, also reduces
//     state machine significantly
//TODO currently we are in the navigationbar and this means we will stay
//     there when the view transitions. Need to work around that.




// this class acts as an NSURLConnectionDelegate proxy
@interface SuProgressNSURLConnection : SuProgress <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
// strong because NSURLConnection treats its delegates as strong
@property (strong, nonatomic) id<NSURLConnectionDelegate, NSURLConnectionDataDelegate> endDelegate;
@end

@interface SuProgressUIWebView : SuProgress <UIWebViewDelegate>
@property (nonatomic) id<UIWebViewDelegate> endDelegate;
@end

static const char *SuAFHTTPRequestOperationViewControllerKey;



// Used inside SuProgressURLConnectionsCreatedInBlock
// making us not-thread safe, but otherwise fine
// yes globals are horrible, but in this case there
// wasn't another solution I could think of that
// wasn't also ugly AND way more code.
static TheKingOfOgres *SuProgressKing;



@implementation UIViewController (SuProgress)

- (void)SuProgressURLConnectionsCreatedInBlock:(void(^)(void))block {
    Class class = [NSURLConnection class];
    id methods = @[@"initWithRequest:delegate:startImmediately:", @"initWithRequest:delegate:"];
    
    for (id method in methods) {
        Method original = class_getInstanceMethod(class, NSSelectorFromString(method));
        Method swizzle = class_getInstanceMethod(class,  NSSelectorFromString([@"SuProgress_" stringByAppendingString:method]));
        method_exchangeImplementations(original, swizzle);
    }

    SuProgressKing = [self SuProgressBar].king;
    block();
    SuProgressKing = nil;

    for (id method in methods) {
        Method original = class_getInstanceMethod(class, NSSelectorFromString(method));
        Method swizzle = class_getInstanceMethod(class,  NSSelectorFromString([@"SuProgress_" stringByAppendingString:method]));
        method_exchangeImplementations(swizzle, original);
    }
}

static UIColor *SuProgressBarColor(UIView *bar) {
    if (![UIView instancesRespondToSelector:@selector(tintColor)])
      #ifdef SuProgressTintColor
        return SuProgressTintColor;
      #else
        return [UIColor blueColor];
      #endif

    CGFloat white, alpha;
    [bar.tintColor getWhite:&white alpha:&alpha];
    if (alpha == 0) {
        NSLog(@"Will not set a completely transparent tintColor, using window.tintColor");
        return bar.window.tintColor;
        CGFloat white, alpha;
        [bar.tintColor getWhite:&white alpha:&alpha];
        if (alpha == 0) {
            NSLog(@"Will not set a completely transparent tintColor, using blueColor");
            return [UIColor blueColor];
        }
    }
    return bar.tintColor;
}

- (SuProgressBarView *)SuProgressBar {
    return [self SuProgressBarInView:nil];
}

- (SuProgressBarView *)SuProgressBarInView:(UIView*)view {
    
    UIView *bar = nil;
    UIView *targetView = nil;
    
    if (view) {
        targetView = view;
    }
    else {
        if (self.navigationController && self.navigationController.navigationBar) {
            UINavigationBar *navbar = self.navigationController.navigationBar;
            targetView = navbar;
        } else {
            NSLog(@"Sorry dude, I haven't written code that supports showing progress in this configuration yet! Fork and help?");
        }
    }
    
    bar = [targetView viewWithTag:SuProgressBarTag];
    if (!bar) {
        bar = [SuProgressBarView new];
        bar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        bar.backgroundColor = SuProgressBarColor(targetView);
        bar.tag = SuProgressBarTag;
        bar.frame = (CGRect){0, targetView.bounds.size.height - SuProgressBarHeight, 0, SuProgressBarHeight};
        [targetView addSubview:bar];
    }
    return (id)bar;
}

- (void)SuProgressForWebView:(UIWebView *)webView {
    [self SuProgressForWebView:webView inView:nil];
}

- (void)SuProgressForWebView:(UIWebView *)webView inView:(UIView*)view {
    SuProgressUIWebView *ogre = [SuProgressUIWebView new];
    ogre.delegate = [self SuProgressBarInView:view].king;
    [[self SuProgressBar].king addOgre:ogre singleUse:NO];
    ogre.endDelegate = webView.delegate;
    webView.delegate = ogre;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

static void SuAFURLHTTPRequest_operationDidStart(id self, SEL _cmd)
{
    UIViewController *vc = objc_getAssociatedObject(self, &SuAFHTTPRequestOperationViewControllerKey);
    [vc SuProgressURLConnectionsCreatedInBlock:^{
        Class superclass = NSClassFromString(@"AFHTTPRequestOperation");
        void (*superIMP)(id, SEL) = (void *)[superclass instanceMethodForSelector:@selector(operationDidStart)];
        superIMP(self, _cmd);
    }];
}

- (void)SuProgressForAFHTTPRequestOperation:(id)operation {
    Class AFHTTPRequestOperation = NSClassFromString(@"AFHTTPRequestOperation");
    
    if (![operation isKindOfClass:AFHTTPRequestOperation]) {
        NSLog(@"SuProgress: Only AFHTTPRequestOperation is supported currently");
        return;
    }
    
    static Class SuAFHTTPRequestOperation = nil;
    if (!SuAFHTTPRequestOperation) {
        SuAFHTTPRequestOperation = objc_allocateClassPair(AFHTTPRequestOperation, "SuAFHTTPRequestOperation", 0);
        
        Method operationDidStart = class_getInstanceMethod(AFHTTPRequestOperation, @selector(operationDidStart));
        const char *types = method_getTypeEncoding(operationDidStart);
        class_addMethod(SuAFHTTPRequestOperation, @selector(operationDidStart), (IMP)SuAFURLHTTPRequest_operationDidStart, types);
    }
    object_setClass(operation, SuAFHTTPRequestOperation);
    objc_setAssociatedObject(operation, &SuAFHTTPRequestOperationViewControllerKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma clang diagnostic pop

@end




enum SuProgressBarViewState {
    SuProgressBarViewReady,
    SuProgressBarViewProgressing,
    SuProgressBarViewFinishing
};




@implementation SuProgressBarView {
    enum SuProgressBarViewState state;
    NSDate *startTime;
    NSDate *waitAtLeastUntil;
}

- (id)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _king = [TheKingOfOgres kingWithDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)finished {   // delegate method TODO name better dumbo
    state = SuProgressBarViewFinishing;

    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        // if we are already filled, then CoreAnimation is smart and this
        // block will finish instantly
        self.frame = (CGRect){0, self.frame.origin.y, self.superview.bounds.size.width, SuProgressBarHeight};
    } completion:^(BOOL finished) {
        if (!finished)
            return;

        NSTimeInterval dt = [[NSDate date] timeIntervalSinceDate:startTime];
        NSTimeInterval dt2 = [waitAtLeastUntil timeIntervalSinceNow];
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
    if (state == SuProgressBarViewFinishing)
        // finishing animation is happening. We are going to just override
        // that, then in finishing animation completion handler we will notice
        // and stop finishing
        state = SuProgressBarViewReady;

    if (state == SuProgressBarViewReady) {
        startTime = [NSDate date];
        waitAtLeastUntil = nil;
        state = SuProgressBarViewProgressing;
        self.frame = (CGRect){self.frame.origin, 0, self.frame.size.height};
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    CGSize sz = self.superview.bounds.size;
    NSTimeInterval duration = 0.3;
    int opts = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseIn;
    [UIView animateWithDuration:duration delay:0 options:opts animations:^{
        self.alpha = 1;
        self.frame = (CGRect){self.frame.origin, sz.width * progress, SuProgressBarHeight};
    } completion:nil];

    waitAtLeastUntil = [NSDate dateWithTimeIntervalSinceNow:duration];
}

- (float)progress {
    return _king.progress;
}

@dynamic progress;
@end




@implementation TheKingOfOgres {
    // We trickle a little when jobs start to indicate
    // progress and trickle ocassionally to indicate that
    // stuff is still happening, so the actual portion of
    // the width that is available for actual progress is
    // less than one.
    NSMutableArray *singleUses;
}
@dynamic progress;

+ (id)kingWithDelegate:(id<KingOfDelegates>)delegate {
    TheKingOfOgres *king = [TheKingOfOgres new];
    king->_delegate = delegate;
    king->_ogres = [NSMutableArray new];
    king->singleUses = [NSMutableArray new];
    return king;
}

- (void)addOgre:(SuProgress *)ogre singleUse:(BOOL)singleUse {
    ogre.delegate = self;
    [_ogres addObject:ogre];
    if (singleUse)
        [singleUses addObject:ogre];
}

- (BOOL)allFinished {
    for (SuProgress *ogre in _ogres)
        if (!ogre.finished)
            return NO;
    return YES;
}

- (void)ogred:(SuProgress *)ogre {
    if (ogre.finished && self.allFinished) {
        [_delegate finished];
        [_ogres removeObjectsInArray:singleUses];
        [_ogres makeObjectsPerformSelector:@selector(reset)];
        [singleUses removeAllObjects];
    } else {
        float progress = 0;
        for (SuProgress *ogre in _ogres)
            progress += ogre.progress;
        progress /= _ogres.count;
        progress *= 0.95;  // only reach 100% when all ogres are finished
        [_delegate progressed:progress];
    }
}

@end




@implementation SuProgress
@dynamic progress;
@synthesize finished;

- (void)reset {
    properProgress = trickled = 0.f;
    finished = NO;
}

- (void)trickle:(float)amount {
    trickled += amount;
}

- (float)progress {
    return (properProgress + trickled) / (1.0 + trickled);
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector] ?: [self.endDelegate respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([self.endDelegate respondsToSelector:invocation.selector])
        [invocation invokeWithTarget:self.endDelegate];
}

- (id)endDelegate {
    return nil;
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

    trickled += 0.1;
    [self.delegate ogred:self];
    
    if ([_endDelegate respondsToSelector:_cmd])
        [_endDelegate connection:connection didReceiveResponse:rsp];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (total_bytes)
        properProgress += (float)data.length / (float)(total_bytes);
    else
        trickled += 0.05;

    void (^block)(void) = ^{
        [self.delegate ogred:self];
    };

    if ([NSThread currentThread] != [NSThread mainThread])
        [[NSOperationQueue mainQueue] addOperationWithBlock:block];
    else
        block();

    if ([_endDelegate respondsToSelector:_cmd])
        [_endDelegate connection:connection didReceiveData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    finished = YES;
    [self.delegate ogred:self];
    if ([_endDelegate respondsToSelector:_cmd])
        [_endDelegate connection:connection didFailWithError:error];
}

- (void)connectionDidFinishLoading:(id)connection {
    finished = YES;
    [self.delegate ogred:self];
    if ([_endDelegate respondsToSelector:_cmd])
        [_endDelegate connectionDidFinishLoading:connection];
}

@end




@implementation NSURLConnection (Debug)

// Annoyingly the unswizzled methods do not defer to one of these
// two so we must swizzle them both with near identical code.

// Our ogre acts as an NSURLConnectionDelegate proxy, and filters
// progress to our progress bar as its intermediary step.
#define SuNSURLConnectionOgreMacro \
    SuProgressNSURLConnection *ogre = [SuProgressNSURLConnection new]; \
    ogre.endDelegate = delegate; \
    [SuProgressKing addOgre:ogre singleUse:YES]

- (id)SuProgress_initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately {
    SuNSURLConnectionOgreMacro;
    return [self SuProgress_initWithRequest:request delegate:ogre startImmediately:startImmediately];
}

- (id)SuProgress_initWithRequest:(NSURLRequest *)request delegate:(id)delegate {
    SuNSURLConnectionOgreMacro;
    return [self SuProgress_initWithRequest:request delegate:ogre];
}

@end




// Welcome to an attempt at a progress bar for UIWebViews
// In brief: it is surprisingly hard.
// Partly because we get so little information from the
// UIWebView, if only we knew more about what was being
// loaded we could probably make more educated guesses
// but as it stands we have to try and guess about rates
// and increment progress in bursts and really, it's all
// just lies. But it looks good and pyschologically
// satisfies users.


@implementation SuProgressUIWebView {
    NSUInteger loading;
    NSUInteger complete;
    NSUInteger bigloading;
    NSUInteger bigcomplete;

    BOOL started;
}

- (void)reset {
    [super reset];
    loading = complete = bigloading = bigcomplete = 0;
    started = NO;
}

-(id)uiWebView:(id)view identifierForInitialRequest:(id)initialRequest fromDataSource:(id)dataSource {
    return @(loading++);
}

- (void)uiWebView:(id)view resource:(id)resource didFailLoadingWithError:(id)error fromDataSource:(id)dataSource
{
    if (started) {
        complete++;
        trickled += 0.01;
        [self.delegate ogred:self];
        [self testdone:view];
    }
}

-(void)uiWebView:(id)view resource:(id)resource didFinishLoadingFromDataSource:(id)dataSource {
    if (started) {
        complete++;
        trickled += 0.01;
        [self.delegate ogred:self];

        [self testdone:view];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
        [self reset];

    return [_endDelegate respondsToSelector:_cmd]
        ? [_endDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType]
        : YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (!started) {
        started = YES;
        trickled += 0.1;
        [self.delegate ogred:self];
    }

    bigloading++;

    if ([_endDelegate respondsToSelector:_cmd])
        [_endDelegate webViewDidStartLoad:webView];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    bigcomplete++;
    if ([_endDelegate respondsToSelector:_cmd])
        [_endDelegate webViewDidFinishLoad:webView];

    [self testdone:webView];
}

- (void)testdone:(id)webView {
    if (loading == complete && bigloading == bigcomplete) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(ontimeout:) withObject:webView afterDelay:0.1];
    }
}

- (void)ontimeout:(UIWebView *)webView {
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    if (loading == complete && bigloading == bigcomplete) {
        if ([readyState isEqualToString:@"complete"]) {
            finished = YES;
            [self.delegate ogred:self];
        } else {
            [self testdone:webView];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    bigcomplete++;
    if ([_endDelegate respondsToSelector:_cmd])
        [_endDelegate webView:webView didFailLoadWithError:error];

    [self testdone:webView];
}

@end
