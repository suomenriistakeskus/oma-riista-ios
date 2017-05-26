#import <Foundation/Foundation.h>

@class Announcement;

typedef void(^RiistaAnnouncementsSyncCompletion)(NSArray *items, NSError *error);

@interface AnnouncementsSync : NSObject

- (void)sync:(RiistaAnnouncementsSyncCompletion)completion;

- (Announcement*)announcementFromDict:(NSDictionary*)dict objectContext:(NSManagedObjectContext*)objectContext;
- (NSDictionary*)dictFromAnnouncement:(Announcement*)announcement;

@end
