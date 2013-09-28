@import UIKit;
#import "SuProgress.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSURLConnectionDelegate> {
    UIViewController *viewController;
    NSMutableDictionary *datas;
    UITextView *textView;
}
@property (strong, nonatomic) UIWindow *window;
@end




@implementation AppDelegate

- (void)fly {
    textView.text = nil;

    id urls = @[
        @"http://mobilemakers.co",
        @"http://theverge.com",
        @"http://methylblue.com/images/as_big.png",
        @"https://www.google.com/#q=foo",
        @"http://methylblue.com/images/Favstand.jpg",
        @"http://methylblue.com/images/zombieland_005.jpeg"
    ];
    [viewController SuProgressURLConnectionsCreatedInBlock:^{
        datas = [NSMutableDictionary new];
        for (id urlstr in urls) {
            id url = [NSURL URLWithString:urlstr];
            id rq = [NSURLRequest requestWithURL:url];
            [NSURLConnection connectionWithRequest:rq delegate:self];
            datas[url] = [NSMutableData new];
        }
    }];
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
    UIButton *button = [self setup];
    [button addTarget:self action:@selector(fly) forControlEvents:UIControlEventTouchUpInside];
    return YES;
}

- (UIButton *)setup {
    // everything in here is for setting up the demo
    // you care about [self fly]

    // disable the NSURLCache so that when you push Go
    // again after the first time, it behaves the same
    // obviously we are doing this for DEMONSTRATION
    // purposes only, don't do this in your app!
    [NSURLCache setSharedURLCache:[[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:@"."]];
    
    viewController = [UIViewController new];
    viewController.title = @"SuProgress Example";

    UINavigationController *navigationController = [UINavigationController new];
    [navigationController pushViewController:viewController animated:NO];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Go" forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectInset(button.frame, -10, -5);
    button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    button.center = (CGPoint){160, 104};
    [viewController.view addSubview:button];
    
    textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 120, 320, 320)];
    [viewController.view addSubview:textView];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];

    return button;
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
