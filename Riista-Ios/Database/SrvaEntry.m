#import "SrvaEntry.h"
#import "SrvaMethod.h"

NSString *const SrvaStateUnfinished = @"UNFINISHED";
NSString *const SrvaStateApproved = @"APPROVED";
NSString *const SrvaStateRejected = @"REJECTED";

@implementation SrvaEntry

- (NSInteger)yearMonth
{
    [self willAccessValueForKey:@"yearMonth"];
    NSInteger yearMonth = [[self valueForKey:@"year"] integerValue] * 12 + [[self valueForKey:@"month"] integerValue];
    [self didAccessValueForKey:@"yearMonth"];
    return yearMonth;
}

- (NSMutableArray<SrvaMethod*>*)parseMethods
{
    if (!self.methods) {
        return [NSMutableArray new];
    }

    NSError *error;
    NSArray* dicts = [NSJSONSerialization JSONObjectWithData:[self.methods dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (dicts != nil) {
        NSMutableArray<SrvaMethod*> *results = [NSMutableArray new];
        for (NSDictionary *dict in dicts) {
            [results addObject:[[SrvaMethod alloc] initWithDictionary:dict]];
        }
        return results;
    }
    return nil;
}

- (void)putMethods:(NSArray<SrvaMethod*>*)methods
{
    NSMutableArray *dicts = [NSMutableArray new];
    for (SrvaMethod *method in methods) {
        [dicts addObject:[method toDict]];
    }

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dicts options:0 error:&error];
    if (!error) {
        self.methods = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    else {
        NSLog(@"Can't serialize methods");
    }
}

- (BOOL)isEditable
{
    return (self.canEdit == nil || [self.canEdit boolValue]);
}

@end
