@import UIKit;
#import "SuProgress.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

#define UIColorPurple [UIColor colorWithRed:0.35f green:0.35f blue:0.81f alpha:1.0f]


@implementation AppDelegate {
    UINavigationController *navigationController;
    UIButton *button;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setup];
    [button addTarget:self action:@selector(fly) forControlEvents:UIControlEventTouchUpInside];

    return YES;
}

- (void)fly {
//    id url = @"http://methylblue.com/images/zombieland_005.jpeg";
    id url = @"http://methylblue.com/images/as_big.png";
    id request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [navigationController.navigationBar followURLConnectionWithRequest:request];
}




- (void)setup {
    UIViewController *vc = [UIViewController new];
    vc.title = @"MMDietProgress Example";
    navigationController = [UINavigationController new];
    [navigationController pushViewController:vc animated:NO];

    button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Go" forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectInset(button.frame, -10, -5);
    button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    button.center = (CGPoint){160, 160};
    [vc.view addSubview:button];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
}

@end


int main(int argc, char **argv) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
