#import "ObservationEntry.h"
#import "DiaryImage.h"
#import "GeoCoordinate.h"
#import "ObservationSpecimen.h"

@implementation ObservationEntry

- (NSInteger)yearMonth
{
    [self willAccessValueForKey:@"yearMonth"];
    NSInteger yearMonth = [[self valueForKey:@"year"] integerValue] * 12 + [[self valueForKey:@"month"] integerValue];
    [self didAccessValueForKey:@"yearMonth"];
    return yearMonth;
}

- (NSInteger)getMooselikeSpecimenCount
{
    NSInteger count = 0;

    count += [self.mooselikeMaleAmount integerValue];
    count += [self.mooselikeFemaleAmount integerValue];
    if (self.mooselikeFemale1CalfAmount) {
        count += [self.mooselikeFemale1CalfAmount integerValue] * (1 + 1);
    }
    if (self.mooselikeFemale2CalfsAmount) {
        count += [self.mooselikeFemale2CalfsAmount integerValue] * (1 + 2);
    }
    if (self.mooselikeFemale3CalfsAmount) {
        count += [self.mooselikeFemale3CalfsAmount integerValue] * (1 + 3);
    }
    if (self.mooselikeFemale4CalfsAmount) {
        count += [self.mooselikeFemale4CalfsAmount integerValue] * (1 + 4);
    }
    count += [self.mooselikeCalfAmount integerValue];
    count += [self.mooselikeUnknownSpecimenAmount integerValue];

    return count;
}

#pragma mark - DiaryEntryBase

- (BOOL)isEditable
{
    return (self.canEdit == nil || [self.canEdit boolValue]);
}

@end
