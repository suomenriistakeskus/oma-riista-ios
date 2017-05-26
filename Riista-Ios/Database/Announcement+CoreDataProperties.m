#import "Announcement+CoreDataProperties.h"

@implementation Announcement (CoreDataProperties)

+ (NSFetchRequest<Announcement *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Announcement"];
}

@dynamic remoteId;
@dynamic rev;
@dynamic pointOfTime;
@dynamic subject;
@dynamic body;
@dynamic sender;

@end
