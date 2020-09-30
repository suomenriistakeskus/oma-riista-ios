#import <CoreData/CoreData.h>

@interface NSManagedObject (RiistaCopying)

- (instancetype) riista_copyInContext:(NSManagedObjectContext *)context;

@end
