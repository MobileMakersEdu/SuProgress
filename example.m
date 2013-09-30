@import UIKit;
#import "SuProgress.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSURLConnectionDelegate, UIWebViewDelegate> {
    UIViewController *connectionsViewController;
    UIViewController *webViewController;
    NSMutableDictionary *datas;
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
        @"http://methylblue.com/images/zombieland_005.jpeg"
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
}

- (void)demoWebView {
    webView.delegate = self;  // you must call the SuProgress method AFTER setting the webView's delegate
    [webViewController SuProgressForWebView:webView];

    id url = [NSURL URLWithString:@"http://theverge.com"];
    id rq = [NSURLRequest requestWithURL:url];
    [webView loadRequest:rq];
}




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

    UITabBarController *tabs = [UITabBarController new];
    tabs.viewControllers = @[
        navigationController1,
        navigationController2
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

@end




int main(int argc, char **argv) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
