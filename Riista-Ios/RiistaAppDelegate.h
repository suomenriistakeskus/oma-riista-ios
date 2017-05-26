#import <UIKit/UIKit.h>

@interface RiistaAppDelegate : UIResponder <UIApplicationDelegate>

- (NSURL*)applicationDocumentsDirectory;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSString *username;

@end
