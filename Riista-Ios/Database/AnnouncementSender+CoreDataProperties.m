#import "AnnouncementSender+CoreDataProperties.h"

@implementation AnnouncementSender (CoreDataProperties)

+ (NSFetchRequest<AnnouncementSender *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"AnnouncementSender"];
}

@dynamic fullName;
@dynamic title;
@dynamic organisation;
@dynamic announcement;

@end
