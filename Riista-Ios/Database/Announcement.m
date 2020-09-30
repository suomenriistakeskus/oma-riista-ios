#import "Announcement.h"
#import "AnnouncementSender.h"
#import "RiistaSettings.h"

@implementation Announcement

- (NSString *)senderAsText
{
    AnnouncementSender *sender = self.sender;
    NSString *langCode = [RiistaSettings language];
    NSString *titleText = [sender.title objectForKey:langCode] ? [sender.title objectForKey:langCode] : [sender.title objectForKey:@"fi"];
    NSString *organisationText = [sender.organisation objectForKey:langCode] ? [sender.organisation objectForKey:langCode] : [sender.organisation objectForKey:@"fi"];

    return [NSString stringWithFormat:@"%@ - %@", titleText, organisationText];
}

- (NSString *)timeAsText
{
    return @"";
}

@end
