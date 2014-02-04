//  Copyright 2013 Max Howell. All rights reserved.
//  BSD licensed. See the README.
//
//  Heavily rewritten for cleaner code styling and pedantic stuff by Tj Fallon

#import "SuProgress.h"

/**
 * Welcome to an attempt at a progress bar for UIWebViews:
 *
 * In brief: it is surprisingly hard.
 * Partly because we get so little information from the
 * UIWebView, if only we knew more about what was being
 * loaded we could probably make more educated guesses
 * but as it stands we have to try and guess about rates
 * and increment progress in bursts and really, it's all
 * just lies. But it looks good and pyschologically
 * satisfies users.
 */
@interface SuWebViewProgress : SuProgress <UIWebViewDelegate>

@property (nonatomic) id<UIWebViewDelegate> endDelegate;

@end