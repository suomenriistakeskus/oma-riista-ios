#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DiaryEntry;

extern NSString *const SpecimenGenderFemale;
extern NSString *const SpecimenGenderMale;
extern NSString *const SpecimenGenderUnknown;

extern NSString *const SpecimenAgeAdult;
extern NSString *const SpecimenAgeYoung;
extern NSString *const SpecimenAgeUnknown;

@interface RiistaSpecimen : NSManagedObject

@property (nonatomic, retain) NSNumber *remoteId;
@property (nonatomic, retain) NSNumber *rev;
@property (nonatomic, retain) NSString *age;
@property (nonatomic, retain) NSString *gender;
@property (nonatomic, retain) NSNumber *weight;

@property (nonatomic, retain) NSNumber *weightEstimated;
@property (nonatomic, retain) NSNumber *weightMeasured;
@property (nonatomic, retain) NSString *fitnessClass;
@property (nonatomic, retain) NSString *antlersType;
@property (nonatomic, retain) NSNumber *antlersWidth;
@property (nonatomic, retain) NSNumber *antlerPointsLeft;
@property (nonatomic, retain) NSNumber *antlerPointsRight;
@property (nonatomic, retain) NSNumber *notEdible;
@property (nonatomic, retain) NSString *additionalInfo;

@property (nonatomic, retain) DiaryEntry *diaryEntry;

- (BOOL)isEqualToRiistaSpecimen:(RiistaSpecimen*)otherSpecimen;
- (BOOL)isEmpty;

@end
