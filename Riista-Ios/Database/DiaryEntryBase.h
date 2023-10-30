extern NSString *const DiaryEntryTypeHarvest;
extern NSString *const DiaryEntryTypeObservation;
extern NSString *const DiaryEntryTypeSrva;

extern NSInteger const DiaryEntryOperationNone;
extern NSInteger const DiaryEntryOperationInsert;
extern NSInteger const DiaryEntryOperationUpdate;
extern NSInteger const DiaryEntryOperationDelete;

extern NSInteger const DiaryEntrySpecimenDetailsMax;

@interface DiaryEntryBase : NSManagedObject

- (BOOL)isEditable;

@end
