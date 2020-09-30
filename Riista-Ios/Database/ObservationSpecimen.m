#import "ObservationSpecimen.h"
#import "ObservationEntry.h"

NSString *const SpecimenAge1To2Years = @"_1TO2Y";
NSString *const SpecimenAgeEraus = @"ERAUS";

@implementation ObservationSpecimen

- (BOOL)isEqualToObservationSpecimen:(ObservationSpecimen*)otherSpecimen
{
    if ([self.remoteId isEqualToNumber:otherSpecimen.remoteId]
        && [self.rev isEqualToNumber:otherSpecimen.rev]
        && [self.age isEqualToString:otherSpecimen.age]
        && [self.gender isEqualToString:otherSpecimen.gender]
        && [self.state isEqualToString:otherSpecimen.state]
        && [self.marking isEqualToString:otherSpecimen.marking]
        && [self.lengthOfPaw isEqualToNumber:otherSpecimen.lengthOfPaw]
        && [self.widthOfPaw isEqualToNumber:otherSpecimen.widthOfPaw]
        )
    {
        return YES;
    }

    return NO;
}

- (BOOL)isEmpty
{
    return !self.age.length
    && !self.gender.length
    && !self.state.length
    && !self.marking.length
    && !self.lengthOfPaw
    && !self.widthOfPaw;
}

@end
