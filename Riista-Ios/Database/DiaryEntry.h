#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "DiaryEntryBase.h"
@class DiaryImage, GeoCoordinate, RiistaSpecimen;

extern NSString *const DiaryEntryHarvestStateCreateReport;
extern NSString *const DiaryEntryHarvestStateProposed;
extern NSString *const DiaryEntryHarvestStateSentForApproval;
extern NSString *const DiaryEntryHarvestStateApproved;
extern NSString *const DiaryEntryHarvestStateRejected;

extern NSString *const DiaryEntryHarvestPermitProposed;
extern NSString *const DiaryEntryHarvestPermitAccepted;
extern NSString *const DiaryEntryHarvestPermitRejected;

@interface DiaryEntry : DiaryEntryBase

// The id of the diary entry (harvest) after it has been migrated to common library
@property (nullable, nonatomic, retain) NSNumber *commonHarvestId;
@property (nonatomic, retain) NSNumber * amount;
@property (nonatomic, retain) NSString * diarydescription;
@property (nonatomic, retain) NSString * deerHuntingType;
@property (nonatomic, retain) NSString * deerHuntingTypeDescription;
@property (nonatomic, retain) NSNumber * gameSpeciesCode;
@property (nonatomic, retain) NSNumber * harvestReportRequired;
@property (nonatomic, retain) NSNumber * harvestReportDone;
@property (nonatomic, retain) NSString * harvestReportState;
@property (nonatomic, retain) NSString * stateAcceptedToHarvestPermit;
@property (nonatomic, retain) NSNumber * canEdit;
@property (nonatomic, retain) NSNumber * month;
@property (nonatomic, retain) NSDate * pointOfTime;
@property (nonatomic, retain) NSNumber * remote;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSNumber * rev;
@property (nonatomic, retain) NSNumber * sent;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) NSNumber * mobileClientRefId;
@property (nonatomic, retain) NSNumber * pendingOperation;
@property (nonatomic, retain) GeoCoordinate *coordinates;
@property (nonatomic, retain) NSSet *diaryImages;
@property (nonatomic, retain) NSOrderedSet *specimens;
@property (nonatomic, retain) NSString *permitNumber;
@property (nonatomic, retain) NSNumber *harvestSpecVersion;
@property (nonatomic, retain) NSString *huntingMethod;
@property (nonatomic, retain) NSNumber *feedingPlace;
@property (nonatomic, retain) NSNumber *taigaBeanGoose;

- (NSInteger)yearMonth;
- (BOOL)hasNonDefaultLocation;

@end

@interface DiaryEntry (CoreDataGeneratedAccessors)

- (void)addDiaryImagesObject:(DiaryImage *)value;
- (void)removeDiaryImagesObject:(DiaryImage *)value;
- (void)addDiaryImages:(NSSet *)values;
- (void)removeDiaryImages:(NSSet *)values;

- (void)addSpecimensObject:(RiistaSpecimen *)value;
- (void)removeSpecimensObject:(RiistaSpecimen *)value;
- (void)addSpecimens:(NSOrderedSet *)values;
- (void)removeSpecimens:(NSOrderedSet *)values;

@end
