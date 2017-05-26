#import <UIKit/UIKit.h>

#import "RiistaAppDelegate.h"
#import "RiistaSettings.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        NSString* languageSetting = [RiistaSettings language];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:languageSetting, nil] forKey:@"AppleLanguages"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        return UIApplicationMain(argc, argv, nil, NSStringFromClass([RiistaAppDelegate class]));
    }
}
