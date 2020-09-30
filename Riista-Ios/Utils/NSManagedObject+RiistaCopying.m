#import "NSManagedObject+RiistaCopying.h"

@implementation NSManagedObject (RiistaCopying)

- (instancetype) riista_copyInContext:(NSManagedObjectContext *)context
{
    return [self riista_copyInContext:context withCache:[NSMutableDictionary new]];
}

- (instancetype) riista_copyInContext:(NSManagedObjectContext *)context withCache:(NSMutableDictionary *)cache
{
    NSManagedObject *copy;

    copy = cache[self.objectID];
    if (copy) return copy;

    copy = [[NSManagedObject alloc] initWithEntity:self.entity insertIntoManagedObjectContext:context];
    cache[self.objectID] = copy;

    // Attributes
    NSArray *keys = [[self.entity attributesByName] allKeys];
    NSDictionary *attributes = [self dictionaryWithValuesForKeys:keys];
    [copy setValuesForKeysWithDictionary:attributes];

    // Relationships
    NSDictionary *relationships = [self.entity relationshipsByName];
    if (0 == relationships.count) return copy;
    id enumerator = ^(NSString *key, NSRelationshipDescription *relationship, BOOL *stop)
    {
        if ([relationship isToMany])
        {
            // Does not support ordered relationships
            NSMutableSet *sourceSet = [self mutableSetValueForKey:key];
            NSMutableSet *targetSet = [copy mutableSetValueForKey:key];
            for (NSManagedObject *value in sourceSet)
            {
                [targetSet addObject:[value riista_copyInContext:context withCache:cache]];
            }
        }
        else
        {
            NSManagedObject *value = [self valueForKey:key];
            value = [value riista_copyInContext:context withCache:cache];
            [copy setValue:value forKey:key];
        }
    };
    [relationships enumerateKeysAndObjectsUsingBlock:enumerator];

    return copy;
}

@end
