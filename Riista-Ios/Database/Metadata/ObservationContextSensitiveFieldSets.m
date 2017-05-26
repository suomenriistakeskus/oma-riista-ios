#import "ObservationContextSensitiveFieldSets.h"


NSString *const kContextSensitiveFieldSetsSpecimenFields = @"specimenFields";
NSString *const kContextSensitiveFieldSetsBaseFields = @"baseFields";
NSString *const kContextSensitiveFieldSetsAllowedStates = @"allowedStates";
NSString *const kContextSensitiveFieldSetsType = @"type";
NSString *const kContextSensitiveFieldSetsWithinMooseHunting = @"withinMooseHunting";
NSString *const kContextSensitiveFieldSetsAllowedMarkings = @"allowedMarkings";
NSString *const kContextSensitiveFieldSetsAllowedAges = @"allowedAges";


@interface ObservationContextSensitiveFieldSets ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation ObservationContextSensitiveFieldSets

@synthesize specimenFields = _specimenFields;
@synthesize baseFields = _baseFields;
@synthesize allowedStates = _allowedStates;
@synthesize type = _type;
@synthesize withinMooseHunting = _withinMooseHunting;
@synthesize allowedMarkings = _allowedMarkings;
@synthesize allowedAges = _allowedAges;


+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    
    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
        self.specimenFields = [self objectOrNilForKey:kContextSensitiveFieldSetsSpecimenFields fromDictionary:dict];
        self.baseFields = [self objectOrNilForKey:kContextSensitiveFieldSetsBaseFields fromDictionary:dict];
        self.allowedStates = [self objectOrNilForKey:kContextSensitiveFieldSetsAllowedStates fromDictionary:dict];
        self.type = [self objectOrNilForKey:kContextSensitiveFieldSetsType fromDictionary:dict];
        self.withinMooseHunting = [[self objectOrNilForKey:kContextSensitiveFieldSetsWithinMooseHunting fromDictionary:dict] boolValue];
        self.allowedMarkings = [self objectOrNilForKey:kContextSensitiveFieldSetsAllowedMarkings fromDictionary:dict];
        self.allowedAges = [self objectOrNilForKey:kContextSensitiveFieldSetsAllowedAges fromDictionary:dict];
    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:[NSDictionary dictionaryWithDictionary:self.specimenFields] forKey:kContextSensitiveFieldSetsSpecimenFields];
    [mutableDict setValue:[NSDictionary dictionaryWithDictionary:self.baseFields] forKey:kContextSensitiveFieldSetsBaseFields];
    NSMutableArray *tempArrayForAllowedStates = [NSMutableArray array];
    for (NSObject *subArrayObject in self.allowedStates) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForAllowedStates addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForAllowedStates addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForAllowedStates] forKey:kContextSensitiveFieldSetsAllowedStates];
    [mutableDict setValue:self.type forKey:kContextSensitiveFieldSetsType];
    [mutableDict setValue:[NSNumber numberWithBool:self.withinMooseHunting] forKey:kContextSensitiveFieldSetsWithinMooseHunting];
    NSMutableArray *tempArrayForAllowedMarkings = [NSMutableArray array];
    for (NSObject *subArrayObject in self.allowedMarkings) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForAllowedMarkings addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForAllowedMarkings addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForAllowedMarkings] forKey:kContextSensitiveFieldSetsAllowedMarkings];
    NSMutableArray *tempArrayForAllowedAges = [NSMutableArray array];
    for (NSObject *subArrayObject in self.allowedAges) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForAllowedAges addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForAllowedAges addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForAllowedAges] forKey:kContextSensitiveFieldSetsAllowedAges];

    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark - Helper Method
- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}


#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.specimenFields = [aDecoder decodeObjectForKey:kContextSensitiveFieldSetsSpecimenFields];
    self.baseFields = [aDecoder decodeObjectForKey:kContextSensitiveFieldSetsBaseFields];
    self.allowedStates = [aDecoder decodeObjectForKey:kContextSensitiveFieldSetsAllowedStates];
    self.type = [aDecoder decodeObjectForKey:kContextSensitiveFieldSetsType];
    self.withinMooseHunting = [aDecoder decodeBoolForKey:kContextSensitiveFieldSetsWithinMooseHunting];
    self.allowedMarkings = [aDecoder decodeObjectForKey:kContextSensitiveFieldSetsAllowedMarkings];
    self.allowedAges = [aDecoder decodeObjectForKey:kContextSensitiveFieldSetsAllowedAges];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_specimenFields forKey:kContextSensitiveFieldSetsSpecimenFields];
    [aCoder encodeObject:_baseFields forKey:kContextSensitiveFieldSetsBaseFields];
    [aCoder encodeObject:_allowedStates forKey:kContextSensitiveFieldSetsAllowedStates];
    [aCoder encodeObject:_type forKey:kContextSensitiveFieldSetsType];
    [aCoder encodeBool:_withinMooseHunting forKey:kContextSensitiveFieldSetsWithinMooseHunting];
    [aCoder encodeObject:_allowedMarkings forKey:kContextSensitiveFieldSetsAllowedMarkings];
    [aCoder encodeObject:_allowedAges forKey:kContextSensitiveFieldSetsAllowedAges];
}

- (id)copyWithZone:(NSZone *)zone
{
    ObservationContextSensitiveFieldSets *copy = [[ObservationContextSensitiveFieldSets alloc] init];
    
    if (copy) {

        copy.specimenFields = [self.specimenFields copyWithZone:zone];
        copy.baseFields = [self.baseFields copyWithZone:zone];
        copy.allowedStates = [self.allowedStates copyWithZone:zone];
        copy.type = [self.type copyWithZone:zone];
        copy.withinMooseHunting = self.withinMooseHunting;
        copy.allowedMarkings = [self.allowedMarkings copyWithZone:zone];
        copy.allowedAges = [self.allowedAges copyWithZone:zone];
    }
    
    return copy;
}

- (BOOL)hasFieldSet:(NSDictionary*)fields name:(NSString*)name
{
    return [fields objectForKey:name];
}

- (BOOL)requiresMooselikeAmounts:(NSDictionary*)fields
{
    return [self hasFieldSet:fields name:@"mooselikeFemaleAmount"];
}

@end
