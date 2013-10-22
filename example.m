@import UIKit;
#import "SuProgress.h"

// uncomment to generate the AFNetworking example as well
//#import "AFNetworking.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSURLConnectionDelegate, UIWebViewDelegate> {
    UIViewController *connectionsViewController;
    UIViewController *webViewController;
    NSMutableDictionary *datas;
  #ifdef _AFNETWORKING_
    UIViewController *afnetworkingController;
  #endif
    UITextView *textView;
    UIWebView *webView;
}
@property (strong, nonatomic) UIWindow *window;
@end



@implementation AppDelegate

- (void)demoConnections {
    textView.text = nil;

    id urls = @[
        @"http://mobilemakers.co",
        @"http://theverge.com",
        @"http://methylblue.com/images/as_big.png",
        @"https://www.google.com/#q=foo",
        @"http://methylblue.com/images/Favstand.jpg",
        @"http://methylblue.com/images/zombieland_005.jpeg",
        @"https://abs.twimg.com/a/1382379960/images/resources/twitter-bird-light-bgs.png"
    ];
    [connectionsViewController SuProgressURLConnectionsCreatedInBlock:^{
        datas = [NSMutableDictionary new];
        for (id urlstr in urls) {
            id url = [NSURL URLWithString:urlstr];
            id rq = [NSURLRequest requestWithURL:url];
            [NSURLConnection connectionWithRequest:rq delegate:self];
            datas[url] = [NSMutableData new];
        }
    }];

//    [connectionsViewController SuProgressURLConnectionsCreatedInBlock:^{
//        __block int count = [urls count];
//        for (id urlstr in urls) {
//            id url = [NSURL URLWithString:urlstr];
//            id rq = [NSURLRequest requestWithURL:url];
//            
//            [NSURLConnection sendAsynchronousRequest:rq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
//                [self appendText:[NSString stringWithFormat:@"Loaded: %@ (%d bytes)", url, [data length]]];
//                if (--count == 0)
//                    [self appendText:@"Done"];
//            }];
//        }
//    }]
}

- (void)demoWebView {
    webView.delegate = self;  // you must call the SuProgress method AFTER setting the webView's delegate
    [webViewController SuProgressForWebView:webView];

    id url = [NSURL URLWithString:@"http://theverge.com"];
    id rq = [NSURLRequest requestWithURL:url];
    [webView loadRequest:rq];
}

#ifdef _AFNETWORKING_
- (void)demoAFNetworking {
    [self fadeOutKittens];

    id url = [NSString stringWithFormat:@"http://placekitten.com/%d/%d", (200 + arc4random() % 120)*2, (200 + arc4random() % 120) * 2];
    url = [NSURL URLWithString:url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:url]];
    op.responseSerializer = [AFImageResponseSerializer serializer];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, UIImage *image) {
        [self addKitten:image];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc] initWithTitle:@"Suckage Occurred!" message:@"So much SUCK" delegate:nil cancelButtonTitle:@"I Concur: It Sucks" otherButtonTitles:nil] show];
    }];
    
    [afnetworkingController SuProgressForAFHTTPRequestOperation:op];
    
    [[NSOperationQueue mainQueue] addOperation:op];
}
#endif



- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [datas[connection.originalRequest.URL] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    id url = connection.originalRequest.URL;
    [self appendText:[NSString stringWithFormat:@"Loaded: %@ (%d bytes)", url, [datas[url] length]]];
    
    [datas removeObjectForKey:url];
    if (datas.count == 0)
        [self appendText:@"Done"];
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setup];
    return YES;
}

- (void)setup {
    // everything in here is for setting up the demo
    // you care about [self fly]

    // disable the NSURLCache so that when you push Go
    // again after the first time, it behaves the same
    // obviously we are doing this for DEMONSTRATION
    // purposes only, don't do this in your app!
    [NSURLCache setSharedURLCache:[[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:@"."]];
    
    CGRect rect = CGRectMake(0, 0, 20, 20);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    UIRectFill(rect);
    UIImage *square = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    connectionsViewController = [UIViewController new];
    connectionsViewController.title = @"NSURLConnection Example";
    connectionsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"NSURLConnection" image:square selectedImage:square];
    
    UINavigationController *navigationController1 = [UINavigationController new];
    [navigationController1 pushViewController:connectionsViewController animated:NO];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Go" forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectInset(button.frame, -10, -5);
    button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    button.center = (CGPoint){160, 104};
    [connectionsViewController.view addSubview:button];
    [button addTarget:self action:@selector(demoConnections) forControlEvents:UIControlEventTouchUpInside];
    
    textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 120, 320, 320)];
    textView.editable = NO;
    [connectionsViewController.view addSubview:textView];
    
    webViewController = [UIViewController new];
    webViewController.title = @"UIWebView Example";
    webViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"UIWebView" image:square selectedImage:square];
    [webViewController.view addSubview:webView = [[UIWebView alloc] initWithFrame:webViewController.view.bounds]];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(demoWebView)];

    UINavigationController *navigationController2 = [UINavigationController new];
    [navigationController2 pushViewController:webViewController animated:NO];

  #ifdef _AFNETWORKING_
    afnetworkingController = [UIViewController new];
    afnetworkingController.title = @"AFNetworking Example";
    afnetworkingController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"AFNetworking" image:square selectedImage:square];
    afnetworkingController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(demoAFNetworking)];
    
    UINavigationController *navigationController3 = [UINavigationController new];
    [navigationController3 pushViewController:afnetworkingController animated:NO];
  #endif

    UITabBarController *tabs = [UITabBarController new];
    tabs.viewControllers = @[
        navigationController1,
        navigationController2,
      #ifdef _AFNETWORKING_
        navigationController3
      #endif
    ];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = tabs;
    [self.window makeKeyAndVisible];
}

- (void)appendText:(id)text {
    text = [@"=> " stringByAppendingString:text];
    textView.text = [[[textView.text componentsSeparatedByString:@"\n"] arrayByAddingObject:text] componentsJoinedByString:@"\n"];
}

#ifdef _AFNETWORKING_
- (void)fadeOutKittens {
    NSArray *views = afnetworkingController.view.subviews;
    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        for (UIView *view in views) {
            view.transform = CGAffineTransformMakeTranslation(0, 300);
            view.alpha = 0;
        }
    } completion:^(BOOL finished) {
        [views makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }];
}

- (void)addKitten:(UIImage *)image {
    UIImageView *iv = [[UIImageView alloc] initWithImage:image];
    [iv sizeToFit];
    iv.center = afnetworkingController.view.center;
    [afnetworkingController.view addSubview:iv];
    iv.alpha = 0;
    iv.transform = CGAffineTransformMakeTranslation(0, -40);
    [UIView animateWithDuration:0.3 animations:^{
        iv.transform = CGAffineTransformIdentity;
        iv.alpha = 1;
    }];
}
#endif

@end




int main(int argc, char **argv) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
