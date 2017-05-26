#import <Foundation/Foundation.h>

@class SpecimenFields, BaseFields;

@interface ObservationContextSensitiveFieldSets : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSDictionary *specimenFields;
@property (nonatomic, strong) NSDictionary *baseFields;
@property (nonatomic, strong) NSArray *allowedStates;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, assign) BOOL withinMooseHunting;
@property (nonatomic, strong) NSArray *allowedMarkings;
@property (nonatomic, strong) NSArray *allowedAges;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

- (BOOL)hasFieldSet:(NSDictionary*)fields name:(NSString*)name;
- (BOOL)requiresMooselikeAmounts:(NSDictionary*)fields;

@end
