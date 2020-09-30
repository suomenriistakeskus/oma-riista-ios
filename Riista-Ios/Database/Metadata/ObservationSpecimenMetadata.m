#import "ObservationSpecimenMetadata.h"
#import "ObservationContextSensitiveFieldSets.h"

#import "Oma_riista-Swift.h"

NSString *const kSpeciesListSpecimenFields = @"specimenFields";
NSString *const kSpeciesListContextSensitiveFieldSets = @"contextSensitiveFieldSets";
NSString *const kSpeciesListGameSpeciesCode = @"gameSpeciesCode";
NSString *const kSpeciesMinPawLength = @"minLengthOfPaw";
NSString *const kSpeciesMaxPawLength = @"maxLengthOfPaw";
NSString *const kSpeciesMinPawWidth = @"minWidthOfPaw";
NSString *const kSpeciesMaxPawWidth = @"maxWidthOfPaw";
NSString *const kSpeciesListBaseFields = @"baseFields";


@implementation ObservationSpecimenMetadata

@synthesize specimenFields = _specimenFields;
@synthesize contextSensitiveFieldSets = _contextSensitiveFieldSets;
@synthesize gameSpeciesCode = _gameSpeciesCode;
@synthesize minLengthOfPaw = _minLengthOfPaw;
@synthesize maxLengthOfPaw = _maxLengthOfPaw;
@synthesize minWidthOfPaw = _minWidthOfPaw;
@synthesize maxWidthOfPaw = _maxWidthOfPaw;
@synthesize baseFields = _baseFields;


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
        self.specimenFields = [RiistaUtils objectOrNilForKey:kSpeciesListSpecimenFields fromDictionary:dict];
        NSObject *receivedContextSensitiveFieldSets = [dict objectForKey:kSpeciesListContextSensitiveFieldSets];
        NSMutableArray *parsedContextSensitiveFieldSets = [NSMutableArray array];
        if ([receivedContextSensitiveFieldSets isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in (NSArray *)receivedContextSensitiveFieldSets) {
                if ([item isKindOfClass:[NSDictionary class]]) {
                    [parsedContextSensitiveFieldSets addObject:[ObservationContextSensitiveFieldSets modelObjectWithDictionary:item]];
                }
            }
        } else if ([receivedContextSensitiveFieldSets isKindOfClass:[NSDictionary class]]) {
            [parsedContextSensitiveFieldSets addObject:[ObservationContextSensitiveFieldSets modelObjectWithDictionary:(NSDictionary *)receivedContextSensitiveFieldSets]];
        }

        self.contextSensitiveFieldSets = [NSArray arrayWithArray:parsedContextSensitiveFieldSets];
        self.gameSpeciesCode = [[RiistaUtils objectOrNilForKey:kSpeciesListGameSpeciesCode fromDictionary:dict] doubleValue];
        self.minLengthOfPaw = [[RiistaUtils objectOrNilForKey:kSpeciesMinPawLength fromDictionary:dict] integerValue];
        self.maxLengthOfPaw = [[RiistaUtils objectOrNilForKey:kSpeciesMaxPawLength fromDictionary:dict] integerValue];
        self.minWidthOfPaw = [[RiistaUtils objectOrNilForKey:kSpeciesMinPawWidth fromDictionary:dict] integerValue];
        self.maxWidthOfPaw = [[RiistaUtils objectOrNilForKey:kSpeciesMaxPawWidth fromDictionary:dict] integerValue];
        self.baseFields = [RiistaUtils objectOrNilForKey:kSpeciesListBaseFields fromDictionary:dict];
    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:[NSDictionary dictionaryWithDictionary:self.specimenFields] forKey:kSpeciesListSpecimenFields];
    NSMutableArray *tempArrayForContextSensitiveFieldSets = [NSMutableArray array];
    for (NSObject *subArrayObject in self.contextSensitiveFieldSets) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForContextSensitiveFieldSets addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForContextSensitiveFieldSets addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForContextSensitiveFieldSets] forKey:kSpeciesListContextSensitiveFieldSets];
    [mutableDict setValue:[NSNumber numberWithDouble:self.gameSpeciesCode] forKey:kSpeciesListGameSpeciesCode];
    [mutableDict setValue:[NSNumber numberWithInteger:self.minLengthOfPaw] forKey:kSpeciesMinPawLength];
    [mutableDict setValue:[NSNumber numberWithInteger:self.maxLengthOfPaw] forKey:kSpeciesMaxPawLength];
    [mutableDict setValue:[NSNumber numberWithInteger:self.minWidthOfPaw] forKey:kSpeciesMinPawWidth];
    [mutableDict setValue:[NSNumber numberWithInteger:self.maxWidthOfPaw] forKey:kSpeciesMaxPawWidth];
    [mutableDict setValue:[NSDictionary dictionaryWithDictionary:self.baseFields] forKey:kSpeciesListBaseFields];

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

    self.specimenFields = [aDecoder decodeObjectForKey:kSpeciesListSpecimenFields];
    self.contextSensitiveFieldSets = [aDecoder decodeObjectForKey:kSpeciesListContextSensitiveFieldSets];
    self.gameSpeciesCode = [aDecoder decodeDoubleForKey:kSpeciesListGameSpeciesCode];
    self.minLengthOfPaw = [aDecoder decodeIntegerForKey:kSpeciesMinPawLength];
    self.maxLengthOfPaw = [aDecoder decodeIntegerForKey:kSpeciesMaxPawLength];
    self.minWidthOfPaw = [aDecoder decodeIntegerForKey:kSpeciesMinPawWidth];
    self.maxWidthOfPaw = [aDecoder decodeIntegerForKey:kSpeciesMaxPawWidth];
    self.baseFields = [aDecoder decodeObjectForKey:kSpeciesListBaseFields];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_specimenFields forKey:kSpeciesListSpecimenFields];
    [aCoder encodeObject:_contextSensitiveFieldSets forKey:kSpeciesListContextSensitiveFieldSets];
    [aCoder encodeDouble:_gameSpeciesCode forKey:kSpeciesListGameSpeciesCode];
    [aCoder encodeObject:_baseFields forKey:kSpeciesListBaseFields];
}

- (id)copyWithZone:(NSZone *)zone
{
    ObservationSpecimenMetadata *copy = [[ObservationSpecimenMetadata alloc] init];
    
    if (copy) {

        copy.specimenFields = [self.specimenFields copyWithZone:zone];
        copy.contextSensitiveFieldSets = [self.contextSensitiveFieldSets copyWithZone:zone];
        copy.gameSpeciesCode = self.gameSpeciesCode;
        copy.baseFields = [self.baseFields copyWithZone:zone];
        copy.minLengthOfPaw = self.minLengthOfPaw;
        copy.maxLengthOfPaw = self.maxLengthOfPaw;
        copy.minWidthOfPaw = self.minWidthOfPaw;
        copy.maxWidthOfPaw = self.maxWidthOfPaw;
    }
    
    return copy;
}

- (NSArray*)getObservationTypes:(ObservationCategory)observationCategory
{
    NSMutableArray *observationTypes = [[NSMutableArray alloc] init];

    for (ObservationContextSensitiveFieldSets *set in self.contextSensitiveFieldSets) {
        if (set.category == observationCategory) {
            [observationTypes addObject:set.type];
        }
    }

    return observationTypes;
}

- (ObservationContextSensitiveFieldSets*)findFieldSetByType:(NSString*)type observationCategory:(ObservationCategory)category
{
    for (ObservationContextSensitiveFieldSets *set in self.contextSensitiveFieldSets) {
        if ([set.type isEqualToString:type] && set.category == category) {
            return set;
        }
    }

    return nil;
}

- (ObservationContextSensitiveFieldSets*)findFieldSetByType:(NSString*)type observationCategoryStr:(NSString*)categoryAsString
{
    // treat unknown categories as normal
    ObservationCategory category = [ObservationCategoryHelper parseWithCategoryString:categoryAsString fallback:ObservationCategoryNormal];
    return [self findFieldSetByType:type observationCategory:category];
}

- (ObservationWithinHuntingCapability)getWithinHuntingCapability:(NSString*)key
{
    NSString* capability = [self.baseFields objectForKey:key];
    return [ObservationWithinHuntingCapabilityParser parseWithCapabilityStr:capability
                                                                   fallback:ObservationWithinHuntingCapabilityUnknown];
}


- (ObservationWithinHuntingCapability)getMooseHuntingCapability
{
    return [self getWithinHuntingCapability:@"withinMooseHunting"];
}

- (ObservationWithinHuntingCapability)getDeerHuntingCapability
{
    return [self getWithinHuntingCapability:@"withinDeerHunting"];
}

@end

