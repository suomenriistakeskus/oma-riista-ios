#import "Announcement.h"
#import "AnnouncementSender.h"
#import "AnnouncementsSync.h"
#import "RiistaAppDelegate.h"
#import "RiistaGameDatabase.h"
#import "RiistaModelUtils.h"
#import "RiistaNetworkManager.h"

@implementation AnnouncementsSync
{
    NSDateFormatter *dateFormatter;
    NSManagedObjectContext *context;
}

- (id)init
{
    self = [super init];
    if (self) {
        dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:ISO_8601];
    }
    return self;
}

- (void)sync:(RiistaAnnouncementsSyncCompletion)completion
{
    RiistaAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = delegate.managedObjectContext;

    [[RiistaNetworkManager sharedInstance] listAnnouncements:^(NSArray *items, NSError *error) {
        if (!error)
        {
            // Delete all existing and insert new ones

            // Could use NSBatchDeleteRequest after iOS8 support is dropped
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:[NSEntityDescription entityForName:@"Announcement" inManagedObjectContext:context]];
            [request setIncludesPropertyValues:NO];

            NSError *fetchError;
            NSArray *toBeDeleted = [context executeFetchRequest:request error:&fetchError];

            for (NSManagedObject *announcement in toBeDeleted) {
                [context deleteObject:announcement];
            }

            for (NSDictionary *dict in items)
            {
                Announcement *announcement = [self announcementFromDict:dict objectContext:context];
                [context insertObject:announcement];
            }

            [RiistaModelUtils saveContexts:context];
        }

        if (completion) {
            if (error) {
                completion(nil, error);
            } else {
                completion(items, nil);
            }
        }
    }];
}

- (Announcement*)announcementFromDict:(NSDictionary*)dict objectContext:(NSManagedObjectContext*)objectContext
{
    NSDate *date = [dateFormatter dateFromString:dict[@"pointOfTime"]];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Announcement" inManagedObjectContext:objectContext];
    Announcement* announcement = [[Announcement alloc] initWithEntity:entity insertIntoManagedObjectContext:objectContext];
    announcement.remoteId = dict[@"id"];
    announcement.rev = dict[@"rev"];
    announcement.pointOfTime = date;
    announcement.subject = [RiistaModelUtils checkNull:dict key:@"subject"];
    announcement.body = [RiistaModelUtils checkNull:dict key:@"body"];

    NSEntityDescription *senderEntity = [NSEntityDescription entityForName:@"AnnouncementSender" inManagedObjectContext:objectContext];
    AnnouncementSender *sender = (AnnouncementSender*)[[NSManagedObject alloc] initWithEntity:senderEntity insertIntoManagedObjectContext:objectContext];
    NSDictionary *senderDict = dict[@"sender"];
    sender.fullName = senderDict[@"fullName"];
    sender.organisation = senderDict[@"organisation"];
    sender.title = senderDict[@"title"];
    [announcement setSender:sender];

    return announcement;
}

- (NSDictionary*)dictFromAnnouncement:(Announcement*)announcement
{
    [NSException raise:@"Not implemented" format:@"Not implemented"];

    return nil;
}

@end
