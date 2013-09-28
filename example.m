@import UIKit;
#import "SuProgress.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    UIViewController *viewController;
}
@property (strong, nonatomic) UIWindow *window;
@end



@implementation AppDelegate

- (void)fly {
    id urls = @[
        @"http://methylblue.com/images/as_big.png",
        @"https://www.google.com/#q=foo",
        @"http://methylblue.com/images/Favstand.jpg",
        @"http://methylblue.com/images/zombieland_005.jpeg"
    ];
    for (id url in urls) {
        id request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];

        // this is how you do it, we can do multiple requests and
        // SuProgress will adjust progress bar accordingly and prettily
        [viewController SuProgressForRequest:request];
    }
}




- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIButton *button = [self setup];
    [button addTarget:self action:@selector(fly) forControlEvents:UIControlEventTouchUpInside];
    return YES;
}

- (UIButton *)setup {
    viewController = [UIViewController new];
    viewController.title = @"MMDietProgress Example";

    UINavigationController *navigationController = [UINavigationController new];
    [navigationController pushViewController:viewController animated:NO];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Go" forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectInset(button.frame, -10, -5);
    button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    button.center = (CGPoint){160, 160};
    [viewController.view addSubview:button];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];

    return button;
}

@end


int main(int argc, char **argv) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
