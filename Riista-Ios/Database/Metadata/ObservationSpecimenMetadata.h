#import <Foundation/Foundation.h>


@class BaseFields;
@class SpecimenFields;
@class ObservationContextSensitiveFieldSets;

typedef NS_ENUM(NSInteger, ObservationCategory);
typedef NS_ENUM(NSInteger, ObservationWithinHuntingCapability);


@interface ObservationSpecimenMetadata : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSDictionary *specimenFields;
@property (nonatomic, strong) NSArray *contextSensitiveFieldSets;
@property (nonatomic, assign) NSInteger gameSpeciesCode;
@property (nonatomic, assign) NSInteger maxLengthOfPaw;
@property (nonatomic, assign) NSInteger minLengthOfPaw;
@property (nonatomic, assign) NSInteger maxWidthOfPaw;
@property (nonatomic, assign) NSInteger minWidthOfPaw;
@property (nonatomic, strong) NSDictionary *baseFields;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (NSArray*)getObservationTypes:(ObservationCategory)observationCategory;
- (ObservationContextSensitiveFieldSets*)findFieldSetByType:(NSString*)type observationCategory:(ObservationCategory)category;
- (ObservationContextSensitiveFieldSets*)findFieldSetByType:(NSString*)type observationCategoryStr:(NSString*)categoryAsString;

- (ObservationWithinHuntingCapability)getMooseHuntingCapability;
- (ObservationWithinHuntingCapability)getDeerHuntingCapability;

@end
