#import <Foundation/Foundation.h>

#import "DiaryEntryBase.h"
#import "ObservationValidator.h"
#import "ObservationEntry.h"
#import "ObservationSpecimenMetadata.h"
#import "ObservationContextSensitiveFieldSets.h"
#import "MetadataManager.h"
#import "GeoCoordinate.h"
#import "RiistaModelUtils.h"
#import "PhoneNumberValidator.h"
#import "Oma_riista-Swift.h"

NSString *const kDeerHuntingType = @"deerHuntingType";
NSString *const kDeerHuntingTypeDescription = @"deerHuntingTypeDescription";

@implementation ObservationValidator

+ (BOOL)validate:(ObservationEntry*)entry metadataManager:(id<MetadataManager>)metadataManager
{
    ObservationSpecimenMetadata *metadata = [metadataManager getObservationMetadataForSpecies:[entry.gameSpeciesCode integerValue]];
    if (!metadata) {
        DDLog(@"%s: No metadata", __PRETTY_FUNCTION__);
        return NO;
    }

    ObservationContextSensitiveFieldSets *fieldset = [metadata findFieldSetByType:entry.observationType observationCategoryStr:entry.observationCategory];
    if (!fieldset) {
        DDLog(@"%s: No species metadata", __PRETTY_FUNCTION__);
        return NO;
    }

    BOOL isDeerPilotUser = [[RiistaSettings userInfo] deerPilotUser];

    BOOL isValid = [self validateSpeciesId:[entry.gameSpeciesCode integerValue]] &&
        [self validateObservationCategory:entry.observationCategory] &&
        [self validateDeerHuntingType:entry fieldset:fieldset isDeerPilotUser:isDeerPilotUser] &&
        [self validateEntryType:entry.type] &&
        [self validatePosition:entry.coordinates] &&
        [self validateTimestamp:entry.pointOfTime] &&
        [self validateObservationType:entry.observationType];

    if (isValid) {
        NSInteger mooselikeCount = [entry getMooselikeSpecimenCount];

        if ([fieldset requiresMooselikeAmounts:fieldset.baseFields]) {
            isValid = mooselikeCount > 0 && entry.totalSpecimenAmount == nil && [entry.specimens count] == 0;

            DDLog(@"Valid: %@ (Amount: %@, specimens: %ld)", isValid ? @"YES" :@"NO", entry.totalSpecimenAmount, (long)[entry.specimens count]);
        }
        else if (mooselikeCount > 0) {
            isValid = false;

            DDLog(@"Valid: %@ (mooselikeCount: %ld)", isValid ? @"YES" :@"NO", (long)mooselikeCount);
        }
        else {
            if ([fieldset hasFieldSet:fieldset.baseFields name:@"amount"] || [RiistaModelUtils isFieldCarnivoreAuthorityVoluntaryForUser:fieldset fieldName:@"amount"]) {
                isValid = [entry.totalSpecimenAmount integerValue] > 0 &&
                    [entry.totalSpecimenAmount integerValue] <= [AppConstants ObservationMaxAmount] &&
                    [entry.specimens count] <= DiaryEntrySpecimenDetailsMax &&
                    (([entry.totalSpecimenAmount integerValue] <= DiaryEntrySpecimenDetailsMax && [entry.specimens count] <= [entry.totalSpecimenAmount integerValue]) ||
                     ([entry.totalSpecimenAmount integerValue] > DiaryEntrySpecimenDetailsMax && [entry.specimens count] == 0));

                DDLog(@"Valid: %@ (Amount: %@, specimens: %ld)", isValid ? @"YES" :@"NO", entry.totalSpecimenAmount, (long)[entry.specimens count]);
            }
            else {
                isValid = entry.totalSpecimenAmount == nil && [entry.specimens count] == 0;

                DDLog(@"Valid: %@ (Amount: %@, specimens: %ld)", isValid ? @"YES" :@"NO", entry.totalSpecimenAmount, (long)[entry.specimens count]);
            }
        }
    }

    if (isValid) {
        isValid = [PhoneNumberValidator isValid:entry.observerPhoneNumber];
    }

    if (!isValid) {
        DDLog(@"Failed to validate observation");
    }

    return isValid;
}

+ (BOOL)validateSpeciesId:(NSInteger)value
{
    if (value > 0) {
        return YES;
    }

    DDLog(@"Illegal species id; %ld", (long)value);
    return NO;
}

+ (BOOL)validateObservationCategory:(NSString*)observationCategory
{
    ObservationCategory category = [ObservationCategoryHelper parseWithCategoryString:observationCategory fallback:ObservationCategoryUnknown];
    if (category != ObservationCategoryUnknown) {
        return YES;
    }

    DDLog(@"Illegal observation category: %@", observationCategory);
    return NO;
}

+ (BOOL)validateDeerHuntingType:(ObservationEntry*)observationEntry fieldset:(ObservationContextSensitiveFieldSets*)fieldset isDeerPilotUser:(BOOL)isDeerPilotUser
{
    DeerHuntingType deerHuntingType = [DeerHuntingTypeHelper parseWithHuntingTypeString:observationEntry.deerHuntingType
                                                                               fallback:DeerHuntingTypeNone];

    BOOL isDeerHuntingTypeRequired = [fieldset hasRequiredBaseField:kDeerHuntingType] ||
        (isDeerPilotUser && [fieldset hasRequiredDeerPilotBaseField:kDeerHuntingType]);

    BOOL isDeerHuntingTypeVoluntary = [fieldset hasVoluntaryBaseField:kDeerHuntingType] ||
        (isDeerPilotUser && [fieldset hasVoluntaryDeerPilotBaseField:kDeerHuntingType]);

    if (isDeerHuntingTypeRequired) {
        if (deerHuntingType == DeerHuntingTypeNone) {
            DDLog(@"no deerHuntingType even though required");
            return NO;
        }
    } else if (!isDeerHuntingTypeVoluntary && deerHuntingType != DeerHuntingTypeNone) {
        DDLog(@"deer hunting type set even though not voluntary");
        return NO;
    }

    NSString *deerHuntingTypeDescription = observationEntry.deerHuntingTypeDescription;

    BOOL isDescriptionRequired = [fieldset hasRequiredBaseField:kDeerHuntingTypeDescription] ||
        (isDeerPilotUser && [fieldset hasRequiredDeerPilotBaseField:kDeerHuntingTypeDescription]);

    BOOL isDescriptionVoluntary = [fieldset hasVoluntaryBaseField:kDeerHuntingTypeDescription] ||
        (isDeerPilotUser && [fieldset hasVoluntaryDeerPilotBaseField:kDeerHuntingTypeDescription]);

    if (isDescriptionRequired) {
        if (deerHuntingTypeDescription == nil) {
            DDLog(@"nil deerHuntingTypeDescription even though required");
            return NO;
        }
    } else if (!isDescriptionVoluntary && deerHuntingTypeDescription != nil) {
        DDLog(@"deer hunting type set even though not voluntary");
        return NO;
    }

    // description must not be present if deerHuntingType is NOT DeerHuntingTypeOther (cannot be expressed by metadata)
    // - i.e. description is only allowed to be nil if type IS Other
    return deerHuntingTypeDescription == nil || deerHuntingType == DeerHuntingTypeOther;
}

+ (BOOL)validateEntryType:(NSString*)value
{
    if ([value isEqual:DiaryEntryTypeObservation]) {
        return YES;
    }

    DDLog(@"Illegal entry type: %@", value);
    return NO;
}

+ (BOOL)validatePosition:(GeoCoordinate*)value
{
    if (![value.latitude isEqualToNumber:[NSNumber numberWithInt:0]] &&
        ![value.longitude isEqualToNumber:[NSNumber numberWithInt:0]] &&
        ([value.source isEqualToString:DiaryEntryLocationGps] || [value.source isEqualToString:DiaryEntryLocationManual]))
    {
        return YES;
    }

    DDLog(@"Illegal position");
    return NO;
}

+ (BOOL)validateTimestamp:(NSDate*)value
{
    if ([value compare:[NSDate date]] == NSOrderedAscending) {
        return YES;
    }

    DDLog(@"Illegal datetime");
    return NO;
}

+ (BOOL)validateObservationType:(NSString*)value
{
    if ([value length] > 0) {
        return YES;
    }

    DDLog(@"Illegal observation type");
    return NO;
}

@end
