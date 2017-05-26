//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ObservationEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface ObservationEntry (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *canEdit;
@property (nullable, nonatomic, retain) NSString *diarydescription;
@property (nullable, nonatomic, retain) NSNumber *gameSpeciesCode;
@property (nullable, nonatomic, retain) NSNumber *linkedToGroupHuntingDay;
@property (nullable, nonatomic, retain) NSNumber *mobileClientRefId;
@property (nullable, nonatomic, retain) NSNumber *month;
@property (nullable, nonatomic, retain) NSNumber *mooselikeFemale1CalfAmount;
@property (nullable, nonatomic, retain) NSNumber *mooselikeFemale2CalfsAmount;
@property (nullable, nonatomic, retain) NSNumber *mooselikeFemale3CalfsAmount;
@property (nullable, nonatomic, retain) NSNumber *mooselikeFemale4CalfsAmount;
@property (nullable, nonatomic, retain) NSNumber *mooselikeFemaleAmount;
@property (nullable, nonatomic, retain) NSNumber *mooselikeMaleAmount;
@property (nullable, nonatomic, retain) NSNumber *mooselikeUnknownSpecimenAmount;
@property (nullable, nonatomic, retain) NSNumber *observationSpecVersion;
@property (nullable, nonatomic, retain) NSString *observationType;
@property (nullable, nonatomic, retain) NSNumber *pendingOperation;
@property (nullable, nonatomic, retain) NSDate *pointOfTime;
@property (nullable, nonatomic, retain) NSNumber *remote;
@property (nullable, nonatomic, retain) NSNumber *remoteId;
@property (nullable, nonatomic, retain) NSNumber *rev;
@property (nullable, nonatomic, retain) NSNumber *sent;
@property (nullable, nonatomic, retain) NSNumber *totalSpecimenAmount;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSNumber *withinMooseHunting;
@property (nullable, nonatomic, retain) NSNumber *year;
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
