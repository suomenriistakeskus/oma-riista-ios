//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "SrvaEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface SrvaEntry (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *remoteId;
@property (nullable, nonatomic, retain) NSNumber *rev;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSDate *pointOfTime;
@property (nullable, nonatomic, retain) NSNumber *gameSpeciesCode;
@property (nullable, nonatomic, retain) NSString *descriptionText;
@property (nullable, nonatomic, retain) NSNumber *canEdit;
@property (nullable, nonatomic, retain) NSString *eventName;
@property (nullable, nonatomic, retain) NSString *eventType;
@property (nullable, nonatomic, retain) NSNumber *totalSpecimenAmount;
@property (nullable, nonatomic, retain) NSString *otherMethodDescription;
@property (nullable, nonatomic, retain) NSString *otherTypeDescription;
@property (nullable, nonatomic, retain) NSString *methods;
@property (nullable, nonatomic, retain) NSNumber *personCount;
@property (nullable, nonatomic, retain) NSNumber *timeSpent;
@property (nullable, nonatomic, retain) NSString *eventResult;
@property (nullable, nonatomic, retain) NSNumber *authorId;
@property (nullable, nonatomic, retain) NSNumber *rhyId;
@property (nullable, nonatomic, retain) NSString *state;
@property (nullable, nonatomic, retain) NSString *otherSpeciesDescription;
@property (nullable, nonatomic, retain) NSString *approverFirstName;
@property (nullable, nonatomic, retain) NSNumber *mobileClientRefId;
@property (nullable, nonatomic, retain) NSNumber *srvaEventSpecVersion;
@property (nullable, nonatomic, retain) NSNumber *sent;
@property (nullable, nonatomic, retain) NSNumber *year;
@property (nullable, nonatomic, retain) NSString *approverLastName;
@property (nullable, nonatomic, retain) NSNumber *authorRev;
@property (nullable, nonatomic, retain) NSString *authorByName;
@property (nullable, nonatomic, retain) NSString *authorLastName;
@property (nullable, nonatomic, retain) NSNumber *month;
@property (nullable, nonatomic, retain) NSNumber *pendingOperation;
@property (nullable, nonatomic, retain) GeoCoordinate *coordinates;
@property (nullable, nonatomic, retain) NSOrderedSet<DiaryImage *> *diaryImages;
@property (nullable, nonatomic, retain) NSOrderedSet<SrvaSpecimen *> *specimens;

@property (nullable, nonatomic, retain) NSString *deportationOrderNumber;
@property (nullable, nonatomic, retain) NSString *eventTypeDetail;
@property (nullable, nonatomic, retain) NSString *otherEventTypeDetailDescription;
@property (nullable, nonatomic, retain) NSString *eventResultDetail;

@end

@interface SrvaEntry (CoreDataGeneratedAccessors)

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

- (void)insertObject:(SrvaSpecimen *)value inSpecimensAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSpecimensAtIndex:(NSUInteger)idx;
- (void)insertSpecimens:(NSArray<SrvaSpecimen *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSpecimensAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSpecimensAtIndex:(NSUInteger)idx withObject:(SrvaSpecimen *)value;
- (void)replaceSpecimensAtIndexes:(NSIndexSet *)indexes withSpecimens:(NSArray<SrvaSpecimen *> *)values;
- (void)addSpecimensObject:(SrvaSpecimen *)value;
- (void)removeSpecimensObject:(SrvaSpecimen *)value;
- (void)addSpecimens:(NSOrderedSet<SrvaSpecimen *> *)values;
- (void)removeSpecimens:(NSOrderedSet<SrvaSpecimen *> *)values;

@end

NS_ASSUME_NONNULL_END
