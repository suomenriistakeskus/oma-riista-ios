#import <Foundation/Foundation.h>

#import "RiistaShootingTestCalendarEventsViewController.h"
#import "RiistaNavigationController.h"
#import "RiistaLocalization.h"
#import "RiistaSettings.h"

@interface RiistaShootingTestCalendarEventsViewController ()

@end

@implementation RiistaShootingTestCalendarEventsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateTitle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)updateTitle
{
    RiistaNavigationController *navController = (RiistaNavigationController*)self.navigationController;
    [navController changeTitle:RiistaLocalizedString(@"Oma riista", nil)];
}

- (void)fetchEvents
{

}

/*
-(void)fetchEvents:(RiistaClubAreaMapCallback)completion
{
    ShootingTestMan

    [self loadMapsFromFile];

    completion(); //Cached maps, if any

    [[RiistaNetworkManager sharedInstance] clubAreaMaps:^(NSArray *items, NSError *error) {
        if (error) {
            completion();
        }
        else {
            NSMutableArray<RiistaClubAreaMap*> *remote = [NSMutableArray new];
            NSMutableArray<RiistaClubAreaMap*> *manuals = [self getManuallyAdded];

            for (int i = 0; i < items.count; i++) {
                NSDictionary *dict = [items objectAtIndex:i];
                if (dict) {
                    RiistaClubAreaMap *map = [[RiistaClubAreaMap alloc] initWithDict:dict];
                    if (map.externalId) {
                        [remote addObject:map];
                    }
                }
            }

            [allMaps removeAllObjects];
            [allMaps addObjectsFromArray:remote];
            [allMaps addObjectsFromArray:manuals];

            [self saveMapsToFile];

            completion();
        }
    }];
}
*/
@end
