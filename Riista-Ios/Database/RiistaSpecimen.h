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
@property (nonatomic, retain) NSNumber *antlersWidth; // 0-200cm
@property (nonatomic, retain) NSNumber *antlerPointsLeft; // 0-30
@property (nonatomic, retain) NSNumber *antlerPointsRight; // 0-30
// 2020 antlers updates
@property (nonatomic, retain) NSNumber *antlersLost;
@property (nonatomic, retain) NSNumber *antlersGirth; // 0-50cm
@property (nonatomic, retain) NSNumber *antlersLength; // 0-100cm
@property (nonatomic, retain) NSNumber *antlersInnerWidth; // 0-100cm
@property (nonatomic, retain) NSNumber *antlersShaftWidth; // 0-10cm
@property (nonatomic, retain) NSNumber *notEdible;
@property (nonatomic, retain) NSNumber *alone;
@property (nonatomic, retain) NSString *additionalInfo;

@property (nonatomic, retain) DiaryEntry *diaryEntry;

- (BOOL)isEqualToRiistaSpecimen:(RiistaSpecimen*)otherSpecimen;
- (BOOL)isEmpty;

@end
