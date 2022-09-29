#import "RiistaAppDelegate.h"
#import "RiistaLocalization.h"
#import "RiistaSessionManager.h"
#import "RiistaSettings.h"
#import "RiistaUtils.h"
#import "UILabel+CustomFont.h"
#import "AnnouncementsSync.h"
#import <GoogleMaps/GoogleMaps.h>
#import <KCOrderedAccessorFix/NSManagedObjectModel+KCOrderedAccessorFix.h>
#import <UserNotifications/UserNotifications.h>
#import "Oma_riista-Swift.h"

@import Firebase;

@implementation RiistaAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupGlobalAppearance];

    _username = @"";

    // The correct GoogleService-Info-<Scheme>.plist file is copied to the name of "GoogleService-Info.plist"
    // in one of the build phases. Obtain the maps api key from there.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
    [GMSServices provideAPIKey:dict[@"API_KEY"]];
    [GMSServices setAbnormalTerminationReportingEnabled:NO];

    // Clear keychain on first run in case of reinstallation
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"FirstRun"]) {
        [[RiistaSessionManager sharedInstance] removeCredentials];
        [[NSUserDefaults standardUserDefaults] setValue:@"1strun" forKey:@"FirstRun"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    // configure Firebase before RiistaSDK is initialized. RiistaSDK initialization
    // will log events to Crashlytics.
    [FIRApp configure];
    [FIRMessaging messaging].delegate = self;

    [RiistaSDKHelper initializeRiistaSDK];

    // Load previous session information
    [[RiistaSessionManager sharedInstance] initializeSession];

    [self registerFirebaseNotifications];
    [self fetchRemoteConfiguration];

    NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notification) {
        //We are launching because the user clicked a notification. Sync announcements.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            //Execute after app delegate init, doesn't really matter when.
            [self syncAnnouncements];
        });
    }

    return YES;
}

- (void)setupGlobalAppearance
{
    [[UILabel appearance] setSubstituteFontName:AppFont.Name];
    [MainNavigationController setupGlobalNavigationBarAppearance];
    [TopLevelTabBarViewController setupGlobalTabBarAppearance];
}

- (void)registerFirebaseNotifications
{
    // Adapted from https://firebase.google.com/docs/cloud-messaging/ios/client
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    UNAuthorizationOptions authOptions =
      UNAuthorizationOptionAlert |
      UNAuthorizationOptionSound |
      UNAuthorizationOptionBadge;
    [[UNUserNotificationCenter currentNotificationCenter]
      requestAuthorizationWithOptions:authOptions
      completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // ...
    }];

    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)fetchRemoteConfiguration
{
    // Spend maximum of couple of seconds at app startup for fetching the current remote configuration.
    // The timeout remote configuraton fetch will not be cancelled if timeout is triggered
    // and thus if we reach the timeout we will still have the new configuration the next time
    // the app is launched
    [RemoteConfigurationManager.sharedInstance fetchRemoteConfigurationWithTimeoutSeconds:3
                                                                        completionHandler:^{
        // activate fetched configuration (may not be the current one)
        [RemoteConfigurationManager.sharedInstance activateRemoteConfigurationWithCompletionHandler:^{
            [self onRemoteConfigurationFetched];
        }];
    }];
}

- (void)onRemoteConfigurationFetched
{
    [CrashlyticsHelper logWithMsg:@"RemoteConfiguration fetched, passing values to RiistaSDK"];
    [RiistaSDKHelper applyRemoteSettings:[RemoteConfigurationManager.sharedInstance riistaSDKSettings]];
    [RiistaSDKHelper prepareAppStartupMessage:[RemoteConfigurationManager.sharedInstance appStartupMessageJson]];
    [RiistaSDKHelper prepareGroupHuntingIntroMessage:[RemoteConfigurationManager.sharedInstance groupHuntingIntroMessageJson]];
    [RiistaSDKHelper overrideHarvestSeasons:[RemoteConfigurationManager.sharedInstance harvestSeasonOverrides]];

    [self attemptReloginIfNeeded];
}

- (void)attemptReloginIfNeeded
{
    RiistaCredentials *credentials = [[RiistaSessionManager sharedInstance] userCredentials];
    if (credentials) {
        [CrashlyticsHelper logWithMsg:@"Attempting re-login"];

        [[RiistaNetworkManager sharedInstance] relogin:credentials.username password:credentials.password completion:^(NSError *error) {
                [[RiistaGameDatabase sharedInstance] initUserSession];
        }];
    };
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self handlePushNotification:application userInfo:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)handlePushNotification:(UIApplication *)application userInfo:(NSDictionary*)userInfo
{
    NSString *announcement = [userInfo valueForKey:@"announcement"];
    if (announcement) {
        [self syncAnnouncements];
    }
}

- (void)syncAnnouncements
{
    AnnouncementsSync *syncer = [AnnouncementsSync new];
    [syncer sync:^(NSArray *items, NSError *error) {
        NSNotification *notification = [NSNotification notificationWithName:RiistaPushAnnouncementKey object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)setUsername:(NSString*)username
{
    _username = username;
    // Setting username resets core data context & coordinator
    self.managedObjectContext = nil;
    self.persistentStoreCoordinator = nil;

    [[NSNotificationCenter defaultCenter] postNotificationName:ManagedObjectContextChangedNotification object:nil];

    [SynchronizationAnalytics sendAppStartupSynchronizationAnalytics];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *objectContext = _managedObjectContext;
    if (objectContext != nil) {
        if ([objectContext hasChanges] && ![objectContext save:&error]) {
            [self showAlert];
        }
    }
}

- (void)showAlert {
    RiistaLanguageRefresh;

    MDCAlertController *alert = [MDCAlertController alertControllerWithTitle:RiistaLocalizedString(@"Error", nil)
                                                                     message:RiistaLocalizedString(@"SavingDataFailed", nil)];
    MDCAlertAction *okAction = [MDCAlertAction actionWithTitle:@"Ok"
                                                       handler:^(MDCAlertAction * _Nonnull action) {
        abort();
    }];

    [alert addAction:okAction];

    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    // Show push messages when app is active.
    completionHandler(UNNotificationPresentationOptionAlert
                      + UNNotificationPresentationOptionSound
                      + UNNotificationPresentationOptionBadge);
}

#pragma mark - FIRMessagingDelegate

- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken
{
    // Implemented but left empty to silence log warnings.
    // FCM token is retrieved in RiistaNetworkManager::registerUserNotificationToken when needed.
}


#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext*)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    // This is a workaround to bug in automatically generated accessors with to-many relationships.
    // Should not break even if Apple ever fixes the bug since all accessor implementations are overridden
    // See: https://github.com/CFKevinRef/KCOrderedAccessorFix
    // http://stackoverflow.com/questions/7385439/exception-thrown-in-nsorderedset-generated-accessors
    [_managedObjectModel kc_generateOrderedSetAccessors];

    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"Riista_%@.sqlite", self.username]];

    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption:@YES,
                              NSInferMappingModelAutomaticallyOption:@YES
                              };

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        [self showAlert];
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end

NSString *const ManagedObjectContextChangedNotification = @"RiistaAppDelegate.ManagedObjectContextChangedNotification";
