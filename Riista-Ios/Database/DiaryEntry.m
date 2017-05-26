#import "DiaryEntry.h"
#import "DiaryImage.h"
#import "GeoCoordinate.h"
#import "RiistaGameDatabase.h"
#import "RiistaSettings.h"

NSString *const DiaryEntryHarvestStateCreateReport = @"createReport";
NSString *const DiaryEntryHarvestStateProposed = @"PROPOSED";
NSString *const DiaryEntryHarvestStateSentForApproval = @"SENT_FOR_APPROVAL";
NSString *const DiaryEntryHarvestStateApproved = @"APPROVED";
NSString *const DiaryEntryHarvestStateRejected = @"REJECTED";

NSString *const DiaryEntryHarvestPermitProposed = @"PROPOSED";
NSString *const DiaryEntryHarvestPermitAccepted = @"ACCEPTED";
NSString *const DiaryEntryHarvestPermitRejected = @"REJECTED";

@implementation DiaryEntry

@dynamic amount;
@dynamic diarydescription;
@dynamic gameSpeciesCode;
@dynamic harvestReportRequired;
@dynamic harvestReportDone;
@dynamic harvestReportState;
@dynamic stateAcceptedToHarvestPermit;
@dynamic canEdit;
@dynamic month;
@dynamic pointOfTime;
@dynamic remote;
@dynamic remoteId;
@dynamic rev;
@dynamic sent;
@dynamic type;
@dynamic year;
@dynamic mobileClientRefId;
@dynamic pendingOperation;
@dynamic coordinates;
@dynamic diaryImages;
@dynamic specimens;
@dynamic permitNumber;
@dynamic harvestSpecVersion;

- (id)init
{
    self = [super init];
    if (self) {
        self.harvestSpecVersion = [NSNumber numberWithInteger:HarvestSpecVersion];
    }
    return self;
}

- (NSInteger)yearMonth
{
    [self willAccessValueForKey:@"yearMonth"];
    NSInteger yearMonth = [[self valueForKey:@"year"] integerValue] * 12 + [[self valueForKey:@"month"] integerValue];
    [self didAccessValueForKey:@"yearMonth"];
    return yearMonth;
}

#pragma mark - DiaryEntryBase

- (BOOL)isEditable
{
    // Allow nil value to support older backend version.
    return (self.canEdit == nil || [self.canEdit boolValue]) && ![self.harvestReportDone boolValue];
}

@end