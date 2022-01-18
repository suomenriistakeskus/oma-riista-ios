#import "RiistaSpecimen.h"
#import "RiistaUtils.h"

NSString *const SpecimenGenderFemale = @"FEMALE";
NSString *const SpecimenGenderMale = @"MALE";
NSString *const SpecimenGenderUnknown = @"UNKNOWN";

NSString *const SpecimenAgeAdult = @"ADULT";
NSString *const SpecimenAgeYoung = @"YOUNG";
NSString *const SpecimenAgeUnknown = @"UNKNOWN";

@implementation RiistaSpecimen

@dynamic remoteId;
@dynamic rev;
@dynamic age;
@dynamic gender;
@dynamic weight;

@dynamic weightEstimated;
@dynamic weightMeasured;
@dynamic fitnessClass;
@dynamic antlersType;
@dynamic antlersWidth;
@dynamic antlerPointsLeft;
@dynamic antlerPointsRight;
@dynamic antlersLost;
@dynamic antlersGirth;
@dynamic antlersLength;
@dynamic antlersInnerWidth;
@dynamic antlersShaftWidth;
@dynamic notEdible;
@dynamic alone;
@dynamic additionalInfo;

@dynamic diaryEntry;

- (BOOL)isEqualToRiistaSpecimen:(RiistaSpecimen*)otherSpecimen
{
    if ([self.remoteId isEqualToNumber:otherSpecimen.remoteId]
        && [self.rev isEqualToNumber:otherSpecimen.rev]
        && [RiistaUtils nilEqual:self.age b:otherSpecimen.age]
        && [RiistaUtils nilEqual:self.gender b:otherSpecimen.gender]
        && [RiistaUtils nilEqual:self.weight b:otherSpecimen.weight]
        && [RiistaUtils nilEqual:self.weightEstimated b:otherSpecimen.weightEstimated]
        && [RiistaUtils nilEqual:self.weightMeasured b:otherSpecimen.weightMeasured]
        && [RiistaUtils nilEqual:self.fitnessClass b:otherSpecimen.fitnessClass]
        && [RiistaUtils nilEqual:self.antlersType b:otherSpecimen.antlersType]
        && [RiistaUtils nilEqual:self.antlersWidth b:otherSpecimen.antlersWidth]
        && [RiistaUtils nilEqual:self.antlerPointsLeft b:otherSpecimen.antlerPointsLeft]
        && [RiistaUtils nilEqual:self.antlerPointsRight b:otherSpecimen.antlerPointsRight]
        && [RiistaUtils nilEqual:self.antlersLost b:otherSpecimen.antlersLost]
        && [RiistaUtils nilEqual:self.antlersGirth b:otherSpecimen.antlersGirth]
        && [RiistaUtils nilEqual:self.antlersLength b:otherSpecimen.antlersLength]
        && [RiistaUtils nilEqual:self.antlersInnerWidth b:otherSpecimen.antlersInnerWidth]
        && [RiistaUtils nilEqual:self.antlersShaftWidth b:otherSpecimen.antlersShaftWidth]
        && [RiistaUtils nilEqual:self.notEdible b:otherSpecimen.notEdible]
        && [RiistaUtils nilEqual:self.alone b:otherSpecimen.alone]
        && [RiistaUtils nilEqual:self.additionalInfo b:otherSpecimen.additionalInfo]
        ) {

        return YES;
    }

    return NO;
}

- (BOOL)isEmpty
{
    return (self.remoteId == nil || [self.remoteId intValue] == 0)
        && !self.age.length
        && !self.gender.length
        && self.weight == nil
        && self.weightEstimated == nil
        && self.weightMeasured == nil
        && !self.fitnessClass.length
        && !self.antlersType.length
        && self.antlersWidth == nil
        && self.antlerPointsLeft == nil
        && self.antlerPointsRight == nil
        && self.antlersLost == nil
        && self.antlersGirth == nil
        && self.antlersLength == nil
        && self.antlersInnerWidth == nil
        && self.antlersShaftWidth == nil
        && self.notEdible == nil
        && self.alone == nil
        && !self.additionalInfo.length;
}

@end
