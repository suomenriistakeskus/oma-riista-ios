#import "ObservationContextSensitiveFieldSets.h"
#import "Oma_riista-Swift.h"


NSString *const kContextSensitiveFieldSetsSpecimenFields = @"specimenFields";
NSString *const kContextSensitiveFieldSetsBaseFields = @"baseFields";
NSString *const kContextSensitiveFieldSetsAllowedStates = @"allowedStates";
NSString *const kContextSensitiveFieldSetsType = @"type";
NSString *const kContextSensitiveFieldSetsCategory = @"category"; // Observation category
NSString *const kContextSensitiveFieldSetsAllowedMarkings = @"allowedMarkings";
NSString *const kContextSensitiveFieldSetsAllowedAges = @"allowedAges";


@implementation ObservationContextSensitiveFieldSets

@synthesize specimenFields = _specimenFields;
@synthesize baseFields = _baseFields;
@synthesize allowedStates = _allowedStates;
@synthesize type = _type;
@synthesize category = _category;
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
        self.specimenFields = [RiistaUtils objectOrNilForKey:kContextSensitiveFieldSetsSpecimenFields fromDictionary:dict];
        self.baseFields = [RiistaUtils objectOrNilForKey:kContextSensitiveFieldSetsBaseFields fromDictionary:dict];
        self.allowedStates = [RiistaUtils objectOrNilForKey:kContextSensitiveFieldSetsAllowedStates fromDictionary:dict];
        self.type = [RiistaUtils objectOrNilForKey:kContextSensitiveFieldSetsType fromDictionary:dict];
        // treat unknown observation categories as normal. This the code won't crash if we're receiving unknown
        // categories within metadata
        self.category = [ObservationCategoryHelper parseWithCategoryString:[RiistaUtils objectOrNilForKey:kContextSensitiveFieldSetsCategory fromDictionary:dict]
                                                                  fallback:ObservationCategoryNormal];
        self.allowedMarkings = [RiistaUtils objectOrNilForKey:kContextSensitiveFieldSetsAllowedMarkings fromDictionary:dict];
        self.allowedAges = [RiistaUtils objectOrNilForKey:kContextSensitiveFieldSetsAllowedAges fromDictionary:dict];
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
    [mutableDict setValue:[ObservationCategoryHelper categoryStringForCategory:self.category] forKey:kContextSensitiveFieldSetsCategory];
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

#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.specimenFields = [aDecoder decodeObjectForKey:kContextSensitiveFieldSetsSpecimenFields];
    self.baseFields = [aDecoder decodeObjectForKey:kContextSensitiveFieldSetsBaseFields];
    self.allowedStates = [aDecoder decodeObjectForKey:kContextSensitiveFieldSetsAllowedStates];
    self.type = [aDecoder decodeObjectForKey:kContextSensitiveFieldSetsType];
    self.category = [ObservationCategoryHelper parseWithCategoryString:[aDecoder decodeObjectForKey:kContextSensitiveFieldSetsCategory]
                                                              fallback:ObservationCategoryNormal];
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
    [aCoder encodeObject:[ObservationCategoryHelper categoryStringForCategory:_category] forKey:kContextSensitiveFieldSetsCategory];
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
        copy.category = self.category;
        copy.allowedMarkings = [self.allowedMarkings copyWithZone:zone];
        copy.allowedAges = [self.allowedAges copyWithZone:zone];
    }

    return copy;
}

- (BOOL)hasFieldWithValue:(NSDictionary*)fields fieldName:(NSString*)fieldName value:(NSString*)value
{
    NSString *fieldValue = [fields objectForKey:fieldName];
    if (fieldValue != nil) {
        return [value isEqualToString:fieldValue];
    }
    return NO;
}

- (BOOL)hasFieldSet:(NSDictionary*)fields name:(NSString*)name
{
    return [fields objectForKey:name] != nil;
}

- (BOOL)hasRequiredBaseField:(NSString*)name
{
    return [self hasFieldWithValue:self.baseFields fieldName:name value:@"YES"];
}

- (BOOL)hasVoluntaryBaseField:(NSString*)name
{
    return [self hasFieldWithValue:self.baseFields fieldName:name value:@"VOLUNTARY"];
}

- (BOOL)hasFieldCarnivoreAuthorityVoluntary:(NSDictionary*)fields name:(NSString*)name
{
    return [self hasFieldWithValue:fields fieldName:name value:@"VOLUNTARY_CARNIVORE_AUTHORITY"];
}

- (BOOL)requiresMooselikeAmounts:(NSDictionary*)fields
{
    return [self hasFieldSet:fields name:@"mooselikeFemaleAmount"];
}

- (BOOL)hasDeerPilotBaseField:(NSString*)name
{
    return [self hasRequiredDeerPilotBaseField:name] || [self hasVoluntaryDeerPilotBaseField:name];
}

- (BOOL)hasRequiredDeerPilotBaseField:(NSString*)name
{
    return [self hasFieldWithValue:self.baseFields fieldName:name value:@"YES_DEER_PILOT"];
}

- (BOOL)hasVoluntaryDeerPilotBaseField:(NSString*)name
{
    return [self hasFieldWithValue:self.baseFields fieldName:name value:@"VOLUNTARY_DEER_PILOT"];
}
@end
