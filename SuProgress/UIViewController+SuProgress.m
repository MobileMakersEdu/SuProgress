//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import "UIViewController+SuProgress.h"

#import "SuProgress.h"
#import "SuWebViewProgress.h"
#import "SuProgressNSURLConnection.h"
#import "SuProgressManager.h"

#import "NSURLConnection+SuProgress.h"
#import "SuProgressBarView.h"

#import <objc/runtime.h>

static NSInteger const kSuProgressBarViewTag            = 51381;


//TODO make each bar a sublayer (or subview for easier animation control)
//     because if new progress occurs during fadeout it should let old bar
//     fadeout still, and new bar should start over the top, also reduces
//     state machine significantly
//TODO currently we are in the navigationbar and this means we will stay
//     there when the view transitions. Need to work around that.


static const char *SuAFHTTPRequestOperationViewControllerKey;

@implementation UIViewController (SuProgress)

- (void)connectionCreationBlock:(void(^)(void))block {
    Class class = [NSURLConnection class];
    id methods = @[@"initWithRequest:delegate:startImmediately:", @"initWithRequest:delegate:"];
    
    for (id method in methods) {
        Method original = class_getInstanceMethod(class, NSSelectorFromString(method));
        Method swizzle = class_getInstanceMethod(class,  NSSelectorFromString([@"SuProgress_" stringByAppendingString:method]));
        method_exchangeImplementations(original, swizzle);
    }
    
    [SuProgressManager setCurrentManager:[self progressBar].manager];
    block();
    [SuProgressManager setCurrentManager:nil];
    
    for (id method in methods) {
        Method original = class_getInstanceMethod(class, NSSelectorFromString(method));
        Method swizzle = class_getInstanceMethod(class,  NSSelectorFromString([@"SuProgress_" stringByAppendingString:method]));
        method_exchangeImplementations(swizzle, original);
    }
}

static UIColor *SuProgressBarColor(UIView *bar) {
    
    if (![UIView instancesRespondToSelector:@selector(tintColor)]) {
#ifdef SuProgressTintColor
        return SuProgressTintColor;
#else
        return [UIColor blueColor];
#endif
    }
    
    CGFloat white, alpha;
    [bar.tintColor getWhite:&white alpha:&alpha];
    
    if (!alpha) {
        NSLog(@"Will not set a completely transparent tintColor, using window.tintColor");
        return bar.window.tintColor;
        CGFloat white, alpha;
        [bar.tintColor getWhite:&white alpha:&alpha];
        if (!alpha) {
            NSLog(@"Will not set a completely transparent tintColor, using blueColor");
            return [UIColor blueColor];
        }
    }
    return bar.tintColor;
}

- (SuProgressBarView *)progressBar {
    UIView *bar = nil;
    if (self.navigationController && self.navigationController.navigationBar) {
        UINavigationBar *navbar = self.navigationController.navigationBar;
        bar = [navbar viewWithTag:kSuProgressBarViewTag];
        if (!bar) {
            bar = [SuProgressBarView new];
            bar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
            bar.backgroundColor = SuProgressBarColor(navbar);
            bar.tag = kSuProgressBarViewTag;
            bar.frame = (CGRect){0, navbar.bounds.size.height - kSuProgressBarHeight, 0, kSuProgressBarHeight};
            [navbar addSubview:bar];
        }
    } else {

        NSLog(@"Sorry dude, I haven't written code that supports showing progress in this configuration yet! Fork and help?");
    }
    return (id)bar;
}

- (void)proxyProgressForWebView:(UIWebView *)webView
{
    SuWebViewProgress *ogre = [SuWebViewProgress new];
    ogre.delegate = [self progressBar].manager;
    [[self progressBar].manager addOgre:ogre singleUse:NO];
    ogre.endDelegate = webView.delegate;
    webView.delegate = ogre;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

static void SuAFURLHTTPRequest_operationDidStart(id self, SEL _cmd)
{
    UIViewController *vc = objc_getAssociatedObject(self, &SuAFHTTPRequestOperationViewControllerKey);
    [vc connectionCreationBlock:^{
        Class superclass = NSClassFromString(@"AFHTTPRequestOperation");
        void (*superIMP)(id, SEL) = (void *)[superclass instanceMethodForSelector:@selector(operationDidStart)];
        superIMP(self, _cmd);
    }];
}

- (void)proxyProgressForAFHTTPRequestOperation:(id)operation {
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


