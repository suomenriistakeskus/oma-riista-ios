#import "ObservationSpecimenMetadata.h"
#import "ObservationContextSensitiveFieldSets.h"


NSString *const kSpeciesListSpecimenFields = @"specimenFields";
NSString *const kSpeciesListContextSensitiveFieldSets = @"contextSensitiveFieldSets";
NSString *const kSpeciesListGameSpeciesCode = @"gameSpeciesCode";
NSString *const kSpeciesListBaseFields = @"baseFields";


@interface ObservationSpecimenMetadata ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation ObservationSpecimenMetadata

@synthesize specimenFields = _specimenFields;
@synthesize contextSensitiveFieldSets = _contextSensitiveFieldSets;
@synthesize gameSpeciesCode = _gameSpeciesCode;
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
        self.specimenFields = [self objectOrNilForKey:kSpeciesListSpecimenFields fromDictionary:dict];
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
        self.gameSpeciesCode = [[self objectOrNilForKey:kSpeciesListGameSpeciesCode fromDictionary:dict] doubleValue];
        self.baseFields = [self objectOrNilForKey:kSpeciesListBaseFields fromDictionary:dict];
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
    [mutableDict setValue:[NSDictionary dictionaryWithDictionary:self.baseFields] forKey:kSpeciesListBaseFields];

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

    self.specimenFields = [aDecoder decodeObjectForKey:kSpeciesListSpecimenFields];
    self.contextSensitiveFieldSets = [aDecoder decodeObjectForKey:kSpeciesListContextSensitiveFieldSets];
    self.gameSpeciesCode = [aDecoder decodeDoubleForKey:kSpeciesListGameSpeciesCode];
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
    }
    
    return copy;
}


- (ObservationContextSensitiveFieldSets*)findFieldSetByType:(NSString*)type withinMooseHunting:(BOOL)withinMooseHunting
{
    for (ObservationContextSensitiveFieldSets *set in self.contextSensitiveFieldSets) {
        if ([set.type isEqualToString:type] && set.withinMooseHunting == withinMooseHunting) {
            return set;
        }
    }

    return nil;
}

- (BOOL)hasBaseFieldSet:(NSString*)name
{
    return [self.baseFields objectForKey:name];
}

@end
