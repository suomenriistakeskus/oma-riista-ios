#import <Foundation/Foundation.h>

@class BaseFields;
@class SpecimenFields;
@class ObservationContextSensitiveFieldSets;

@interface ObservationSpecimenMetadata : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSDictionary *specimenFields;
@property (nonatomic, strong) NSArray *contextSensitiveFieldSets;
@property (nonatomic, assign) NSInteger gameSpeciesCode;
@property (nonatomic, strong) NSDictionary *baseFields;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (ObservationContextSensitiveFieldSets*)findFieldSetByType:(NSString*)type withinMooseHunting:(BOOL)withinMooseHunting;
- (BOOL)hasBaseFieldSet:(NSString*)name;

@end
