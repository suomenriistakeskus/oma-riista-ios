#import "ObservationEntry.h"


NS_ASSUME_NONNULL_BEGIN

@interface ObservationEntry (CoreDataProperties)

+ (NSFetchRequest<ObservationEntry *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *canEdit;
@property (nullable, nonatomic, copy) NSString *diarydescription;
@property (nullable, nonatomic, copy) NSNumber *gameSpeciesCode;
@property (nullable, nonatomic, copy) NSNumber *inYardDistanceToResidence;
@property (nullable, nonatomic, copy) NSNumber *linkedToGroupHuntingDay;
@property (nullable, nonatomic, copy) NSNumber *litter;
@property (nullable, nonatomic, copy) NSNumber *mobileClientRefId;
@property (nullable, nonatomic, copy) NSNumber *month;
@property (nullable, nonatomic, copy) NSNumber *mooselikeCalfAmount;
@property (nullable, nonatomic, copy) NSNumber *mooselikeFemale1CalfAmount;
@property (nullable, nonatomic, copy) NSNumber *mooselikeFemale2CalfsAmount;
@property (nullable, nonatomic, copy) NSNumber *mooselikeFemale3CalfsAmount;
@property (nullable, nonatomic, copy) NSNumber *mooselikeFemale4CalfsAmount;
@property (nullable, nonatomic, copy) NSNumber *mooselikeFemaleAmount;
@property (nullable, nonatomic, copy) NSNumber *mooselikeMaleAmount;
@property (nullable, nonatomic, copy) NSNumber *mooselikeUnknownSpecimenAmount;
@property (nullable, nonatomic, copy) NSString *observationCategory;
@property (nullable, nonatomic, copy) NSNumber *observationSpecVersion;
@property (nullable, nonatomic, copy) NSString *observationType;
@property (nullable, nonatomic, copy) NSString *deerHuntingType; // used when observation was made within deer hunting
@property (nullable, nonatomic, copy) NSString *deerHuntingTypeDescription;
@property (nullable, nonatomic, copy) NSString *observerName;
@property (nullable, nonatomic, copy) NSString *observerPhoneNumber;
@property (nullable, nonatomic, copy) NSString *officialAdditionalInfo;
@property (nullable, nonatomic, copy) NSNumber *pack;
@property (nullable, nonatomic, copy) NSNumber *pendingOperation;
@property (nullable, nonatomic, copy) NSDate *pointOfTime;
@property (nullable, nonatomic, copy) NSNumber *remote;
@property (nullable, nonatomic, copy) NSNumber *remoteId;
@property (nullable, nonatomic, copy) NSNumber *rev;
@property (nullable, nonatomic, copy) NSNumber *sent;
@property (nullable, nonatomic, copy) NSNumber *totalSpecimenAmount;
@property (nullable, nonatomic, copy) NSString *type;
@property (nullable, nonatomic, copy) NSNumber *verifiedByCarnivoreAuthority;
@property (nullable, nonatomic, copy) NSNumber *withinMooseHunting;
@property (nullable, nonatomic, copy) NSNumber *year;
@property (nullable, nonatomic, retain) GeoCoordinate *coordinates;
@property (nullable, nonatomic, retain) NSOrderedSet<DiaryImage *> *diaryImages;
@property (nullable, nonatomic, retain) NSOrderedSet<ObservationSpecimen *> *specimens;

@end

@interface ObservationEntry (CoreDataGeneratedAccessors)

- (void)insertObject:(DiaryImage *)value inDiaryImagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDiaryImagesAtIndex:(NSUInteger)idx;
- (void)insertDiaryImages:(NSArray<DiaryImage *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDiaryImagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDiaryImagesAtIndex:(NSUInteger)idx withObject:(DiaryImage *)value;
- (void)replaceDiaryImagesAtIndexes:(NSIndexSet *)indexes withDiaryImages:(NSArray<DiaryImage *> *)values;
- (void)addDiaryImagesObject:(DiaryImage *)value;
- (void)removeDiaryImagesObject:(DiaryImage *)value;
- (void)addDiaryImages:(NSOrderedSet<DiaryImage *> *)values;
- (void)removeDiaryImages:(NSOrderedSet<DiaryImage *> *)values;

- (void)insertObject:(ObservationSpecimen *)value inSpecimensAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSpecimensAtIndex:(NSUInteger)idx;
- (void)insertSpecimens:(NSArray<ObservationSpecimen *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSpecimensAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSpecimensAtIndex:(NSUInteger)idx withObject:(ObservationSpecimen *)value;
- (void)replaceSpecimensAtIndexes:(NSIndexSet *)indexes withSpecimens:(NSArray<ObservationSpecimen *> *)values;
- (void)addSpecimensObject:(ObservationSpecimen *)value;
- (void)removeSpecimensObject:(ObservationSpecimen *)value;
- (void)addSpecimens:(NSOrderedSet<ObservationSpecimen *> *)values;
- (void)removeSpecimens:(NSOrderedSet<ObservationSpecimen *> *)values;

@end

NS_ASSUME_NONNULL_END
