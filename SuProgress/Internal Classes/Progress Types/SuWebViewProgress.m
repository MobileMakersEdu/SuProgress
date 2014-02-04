//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import "SuWebViewProgress.h"

@interface SuWebViewProgress ()

@property NSUInteger loading;
@property NSUInteger complete;
@property NSUInteger bigloading;
@property NSUInteger bigcomplete;

@property BOOL started;

@end

@implementation SuWebViewProgress

- (void)reset
{
    [super reset];
    
    self.loading = self.complete = self.bigloading = self.bigcomplete = 0;
    self.started = NO;
}

- (id)uiWebView:(id)view identifierForInitialRequest:(id)initialRequest fromDataSource:(id)dataSource
{
    return @(self.loading++);
}

- (void)uiWebView:(id)view resource:(id)resource didFailLoadingWithError:(id)error fromDataSource:(id)dataSource
{
    if (self.started) {
        self.complete++;
        self.trickled += 0.01;
        [self.delegate progressed:self];
        [self testdone:view];
    }
}

- (void)uiWebView:(id)view resource:(id)resource didFinishLoadingFromDataSource:(id)dataSource
{
    if (self.started) {
        self.complete++;
        self.trickled += 0.01;
        [self.delegate progressed:self];
        
        [self testdone:view];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [self reset];
    }
    
    if ([self.endDelegate respondsToSelector:_cmd]) {
        return [self.endDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    } else {
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (!self.started) {
        self.started = YES;
        self.trickled += 0.1;
        [self.delegate progressed:self];
    }
    
    self.bigloading++;
    
    if ([self.endDelegate respondsToSelector:_cmd]) {
        [self.endDelegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.bigcomplete++;
    
    if ([self.endDelegate respondsToSelector:_cmd]) {
        [self.endDelegate webViewDidFinishLoad:webView];
    }
    
    [self testdone:webView];
}

- (void)testdone:(id)webView
{
    if (self.loading == self.complete &&
        self.bigloading == self.bigcomplete)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(ontimeout:) withObject:webView afterDelay:0.1];
    }
}

- (void)ontimeout:(UIWebView *)webView
{
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    
    if (self.loading == self.complete &&
        self.bigloading == self.bigcomplete)
    {
        if ([readyState isEqualToString:@"complete"]) {
            self.finished = YES;
            [self.delegate progressed:self];
        } else {
            [self testdone:webView];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    self.bigcomplete++;
    
    if ([self.endDelegate respondsToSelector:_cmd]) {
        [self.endDelegate webView:webView didFailLoadWithError:error];
    }
    
    [self testdone:webView];
}

@end
