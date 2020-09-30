#import <GoogleMaps/GoogleMaps.h>
#import <Foundation/Foundation.h>
#import "RiistaMapAreasViewController.h"
#import "RiistaMapViewController.h"
#import "RiistaLocalization.h"

@interface RiistaMapAreasViewController () <RiistaPageDelegate>
@end

@implementation RiistaMapAreasViewController
{
    RiistaMapViewController *mapController;
    BOOL presented;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self refreshTabItem];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    presented = NO;

    self.definesPresentationContext = YES;

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"DetailsStoryboard" bundle:nil];
    mapController = [sb instantiateViewControllerWithIdentifier:@"mapPageController"];
    //controller.delegate = self;
    mapController.editMode = NO;
    //controller.location = self.selectedLocation;
    mapController.riistaController = (RiistaNavigationController*)self.navigationController;
    mapController.titlePrimaryText = RiistaLocalizedString(@"Map", nil);
    mapController.modalPresentationStyle = UIModalPresentationCurrentContext;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!presented) {
        presented = YES;

        [self presentViewController:mapController animated:NO completion:nil];
    }
    [self pageSelected];
}

- (void)pageSelected
{
    //Let MapViewController set the title
}

- (void)refreshTabItem
{
    self.tabBarItem.title = RiistaLocalizedString(@"Map", nil);

    // Refresh title when language setting changes. Since view is presented as modal the normal lifecycle methods
    // of this controller are not called
    if (mapController != nil) {
        mapController.titlePrimaryText = RiistaLocalizedString(@"Map", nil);
    }
}

@end

