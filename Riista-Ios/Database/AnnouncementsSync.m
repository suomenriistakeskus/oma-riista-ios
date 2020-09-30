#import "Announcement.h"
#import "AnnouncementSender.h"
#import "AnnouncementsSync.h"
#import "RiistaAppDelegate.h"
#import "RiistaGameDatabase.h"
#import "RiistaModelUtils.h"
#import "RiistaUtils.h"
#import "RiistaNetworkManager.h"
#import "NSDateformatter+Locale.h"

@implementation AnnouncementsSync
{
    NSDateFormatter *dateFormatter;
    NSManagedObjectContext *context;
}

- (id)init
{
    self = [super init];
    if (self) {
        dateFormatter = [[NSDateFormatter alloc] initWithSafeLocale];
        [dateFormatter setDateFormat:ISO_8601];
    }
    return self;
}

- (void)sync:(RiistaAnnouncementsSyncCompletion)completion
{
    RiistaAppDelegate *delegate = (RiistaAppDelegate *)[[UIApplication sharedApplication] delegate];
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = delegate.managedObjectContext;

    [[RiistaNetworkManager sharedInstance] listAnnouncements:^(NSArray *items, NSError *error) {
        if (!error)
        {
            // Delete all existing and insert new ones

            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:[NSEntityDescription entityForName:@"Announcement" inManagedObjectContext:self->context]];

            NSError *fetchError;
            NSArray *toBeDeleted = [self->context executeFetchRequest:request error:&fetchError];
            NSMutableDictionary* existing = [NSMutableDictionary new];

            for (NSManagedObject *announcement in toBeDeleted) {
                Announcement *ann = (Announcement*)announcement;
                [existing setObject:@{@"rev": ann.rev} forKey:ann.remoteId];

                [self->context deleteObject:announcement];
            }

            for (NSDictionary *dict in items)
            {
                Announcement *announcement = [self announcementFromDict:dict objectContext:self->context];
                [self->context insertObject:announcement];

                NSDictionary *old = [existing objectForKey:announcement.remoteId];
                if (old == nil || [announcement.rev integerValue] > [[old objectForKey:@"rev"] integerValue]) {
                    //This is a new or a changed announcement.
                    [RiistaUtils addUnreadAnnouncement:announcement.remoteId];
                }
            }

            [RiistaModelUtils saveContexts:self->context];
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
    sender.fullName = [RiistaModelUtils checkNull:senderDict key:@"fullName"];
    sender.organisation = [RiistaModelUtils checkNull:senderDict key:@"organisation"];
    sender.title = [RiistaModelUtils checkNull:senderDict key:@"title"];
    [announcement setSender:sender];

    return announcement;
}

- (NSDictionary*)dictFromAnnouncement:(Announcement*)announcement
{
    [NSException raise:@"Not implemented" format:@"Not implemented"];

    return nil;
}

@end
