#import "ObservationEntry+CoreDataProperties.h"
#import "Oma_riista-Swift.h"

@implementation ObservationEntry (CoreDataProperties)

+ (NSFetchRequest<ObservationEntry *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"ObservationEntry"];
}

@dynamic canEdit;
@dynamic diarydescription;
@dynamic gameSpeciesCode;
@dynamic inYardDistanceToResidence;
@dynamic linkedToGroupHuntingDay;
@dynamic litter;
@dynamic mobileClientRefId;
@dynamic month;
@dynamic mooselikeCalfAmount;
@dynamic mooselikeFemale1CalfAmount;
@dynamic mooselikeFemale2CalfsAmount;
@dynamic mooselikeFemale3CalfsAmount;
@dynamic mooselikeFemale4CalfsAmount;
@dynamic mooselikeFemaleAmount;
@dynamic mooselikeMaleAmount;
@dynamic mooselikeUnknownSpecimenAmount;
@dynamic observationCategory;

/**
 This is really a calculated property due to the fact that database migrations are not performed linearly
 i.e. core data can skip migrations by going straight from v12 to v14 (and using inferred migration).

 We need a proper linear migration support in order to be able to fully trust that there is an observationCategory
 for each ObservationEntry. Let's make sure we've got a value for observationCategory since it is possible that
 the migration (v12->v13) containing observationCategory calculation is skipped.
 */
- (NSString*)observationCategory
{
    [self willAccessValueForKey:@"observationCategory"];
    NSString* primitiveObservationCategory = [self primitiveValueForKey:@"observationCategory"];
    [self didAccessValueForKey:@"observationCategory"];

    // default to using primitive category if there's one. All new entries should have this.
    if (primitiveObservationCategory) {
        return primitiveObservationCategory;
    }

    // for older entries calculate observation category from 'withinMooseHunting'
    [self willAccessValueForKey:@"withinMooseHunting"];
    NSNumber* withinMooseHunting = [self primitiveValueForKey:@"withinMooseHunting"];
    [self didAccessValueForKey:@"withinMooseHunting"];

    ObservationCategory observationCategory = ObservationCategoryNormal;
    if (withinMooseHunting && [withinMooseHunting boolValue]) {
        observationCategory = ObservationCategoryMooseHunting;
    }

    return [ObservationCategoryHelper categoryStringForCategory:observationCategory];
}

@dynamic observationSpecVersion;
@dynamic observationType;
@dynamic deerHuntingType;
@dynamic deerHuntingTypeDescription;
@dynamic observerName;
@dynamic observerPhoneNumber;
@dynamic officialAdditionalInfo;
@dynamic pack;
@dynamic pendingOperation;
@dynamic pointOfTime;
@dynamic remote;
@dynamic remoteId;
@dynamic rev;
@dynamic sent;
@dynamic totalSpecimenAmount;
@dynamic type;
@dynamic verifiedByCarnivoreAuthority;
@dynamic withinMooseHunting;
@dynamic year;
@dynamic coordinates;
@dynamic diaryImages;
@dynamic specimens;

@end
