#import <Foundation/Foundation.h>

#import "DiaryEntryBase.h"
#import "ObservationValidator.h"
#import "ObservationEntry.h"
#import "ObservationSpecimenMetadata.h"
#import "ObservationContextSensitiveFieldSets.h"
#import "MetadataManager.h"
#import "GeoCoordinate.h"

@implementation ObservationValidator

+ (BOOL)validate:(ObservationEntry*)entry metadataManager:(id<MetadataManager>)metadataManager
{
    ObservationSpecimenMetadata *metadata = [metadataManager getObservationMetadataForSpecies:[entry.gameSpeciesCode integerValue]];
    if (!metadata) {
        DLog(@"%s: No metadata", __PRETTY_FUNCTION__);
        return NO;
    }

    ObservationContextSensitiveFieldSets *fieldset = [metadata findFieldSetByType:entry.observationType withinMooseHunting:[entry.withinMooseHunting boolValue]];
    if (!fieldset) {
        DLog(@"%s: No species metadata", __PRETTY_FUNCTION__);
        return NO;
    }

    BOOL isValid = [self validateSpeciesId:[entry.gameSpeciesCode integerValue]] &&
        [self validateEntryType:entry.type] &&
        [self validatePosition:entry.coordinates] &&
        [self validateTimestamp:entry.pointOfTime] &&
        [self validateObservationType:entry.observationType];

    if (isValid) {
        NSInteger mooselikeCount = [entry getMooselikeSpecimenCount];

        if ([fieldset requiresMooselikeAmounts:fieldset.baseFields]) {
            isValid = mooselikeCount > 0 && entry.totalSpecimenAmount == nil && [entry.specimens count] == 0;

            DLog(@"Valid: %@ (Amount: %@, specimens: %ld)", isValid ? @"YES" :@"NO", entry.totalSpecimenAmount, [entry.specimens count]);
        }
        else if (mooselikeCount > 0) {
            isValid = false;

            DLog(@"Valid: %@ (mooselikeCount: %ld)", isValid ? @"YES" :@"NO", (long)mooselikeCount);
        }
        else {
            if ([fieldset hasFieldSet:fieldset.baseFields name:@"amount"]) {
                isValid = [entry.totalSpecimenAmount integerValue] > 0 &&
                    [entry.totalSpecimenAmount integerValue] <= 999 &&
                    [entry.specimens count] <= DiaryEntrySpecimenDetailsMax &&
                    (([entry.totalSpecimenAmount integerValue] <= DiaryEntrySpecimenDetailsMax && [entry.specimens count] <= [entry.totalSpecimenAmount integerValue]) ||
                     ([entry.totalSpecimenAmount integerValue] > DiaryEntrySpecimenDetailsMax && [entry.specimens count] == 0));

                DLog(@"Valid: %@ (Amount: %@, specimens: %ld)", isValid ? @"YES" :@"NO", entry.totalSpecimenAmount, [entry.specimens count]);
            }
            else {
                isValid = entry.totalSpecimenAmount == nil && [entry.specimens count] == 0;

                DLog(@"Valid: %@ (Amount: %@, specimens: %ld)", isValid ? @"YES" :@"NO", entry.totalSpecimenAmount, [entry.specimens count]);
            }
        }
    }

    if (!isValid) {
        DLog(@"Failed to validate observation");
    }

    return isValid;
}

+ (BOOL)validateSpeciesId:(NSInteger)value
{
    if (value > 0) {
        return YES;
    }

    DLog(@"Illegal species id; %ld", value);
    return NO;
}

+ (BOOL)validateEntryType:(NSString*)value
{
    if ([value isEqual:DiaryEntryTypeObservation]) {
        return YES;
    }

    DLog(@"Illegal entry type: %@", value);
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

    DLog(@"Illegal position");
    return NO;
}

+ (BOOL)validateTimestamp:(NSDate*)value
{
    if ([value compare:[NSDate date]] == NSOrderedAscending) {
        return YES;
    }

    DLog(@"Illegal datetime");
    return NO;
}

+ (BOOL)validateObservationType:(NSString*)value
{
    if ([value length] > 0) {
        return YES;
    }

    DLog(@"Illegal observation type");
    return NO;
}

+ (BOOL)validateAmount:(NSNumber*)value metadata:(ObservationSpecimenMetadata*)metadata observationType:(NSString*)observationType withinMooseHunting:(BOOL)withinMooseHunting;
{
    if (metadata == nil) {
        return NO;
    }

    ObservationContextSensitiveFieldSets *fieldset = [metadata findFieldSetByType:observationType withinMooseHunting:withinMooseHunting];
    if (fieldset == nil) {
        return NO;
    }

    if ([fieldset hasFieldSet:fieldset.baseFields name:@"amount"]) {
        return [value intValue] > 0 && [value intValue] <= 999;
    }
    else {
        return value == nil;
    }
}

+ (BOOL)validateSpecimens:(NSOrderedSet*)value amount:(NSInteger)amount
{
    if (value != nil && [value count] <= amount) {
        return YES;
    }

    DLog(@"Illegal specimen information");
    return NO;
}

@end
