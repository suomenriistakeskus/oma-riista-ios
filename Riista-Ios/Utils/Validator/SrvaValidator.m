#import "SrvaValidator.h"
#import "RiistaMetadataManager.h"
#import "SrvaMetadata.h"
#import "SrvaEntry.h"
#import "RiistaGameDatabase.h"
#import "RiistaSpecies.h"

@implementation SrvaValidator

+ (BOOL)validate:(SrvaEntry*)entry
{
    RiistaMetadataManager* manager = [RiistaMetadataManager sharedInstance];
    SrvaMetadata *metadata = [manager getSrvaMetadata];
    if (metadata == nil) {
        DLog(@"%s: No SRVA metadata", __PRETTY_FUNCTION__);
        return NO;
    }

    if ([self isEmpty:entry.eventName] ||
        [self isEmpty:entry.eventType] ||
        entry.coordinates == nil ||
        [entry.totalSpecimenAmount integerValue] <= 0 ||
        entry.specimens.count <= 0) {
            return NO;
    }

    if (entry.gameSpeciesCode == nil && [self isEmpty:entry.otherSpeciesDescription]) {
        return NO;
    }
    if (entry.gameSpeciesCode != nil && ![self isEmpty:entry.otherSpeciesDescription]) {
        return NO;
    }
    if (entry.gameSpeciesCode != nil) {
        RiistaSpecies *species = [[RiistaGameDatabase sharedInstance] speciesById:[entry.gameSpeciesCode integerValue]];
        if (species == nil) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)isEmpty:(NSString*)string
{
    if (string != nil) {
        return string.length == 0 ? YES : NO;
    }
    return YES;
}

@end
