#import <UIKit/UIKit.h>

#ifdef ISH_FALLTHROUGH
#undef ISH_FALLTHROUGH
#endif


@interface ISHAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation ISHAppDelegate

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor blackColor];

    UILabel *label = [[UILabel alloc] initWithFrame:vc.view.bounds];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor greenColor];
    label.numberOfLines = 0;
    label.text = @"iSH64 iOS stub build\n(Engine wired via CMake/Xcode)\n\nNext step: hook the TTY/UI.";
    [vc.view addSubview:label];

    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([ISHAppDelegate class]));
    }
}
