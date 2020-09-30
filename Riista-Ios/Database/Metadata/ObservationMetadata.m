#import "ObservationMetadata.h"
#import "ObservationSpecimenMetadata.h"
#import "RiistaUtils.h"

NSString *const kBaseClassObservationSpecVersion = @"observationSpecVersion";
NSString *const kBaseClassLastModified = @"lastModified";
NSString *const kBaseClassSpeciesList = @"speciesList";


@implementation ObservationMetadata

@synthesize observationSpecVersion = _observationSpecVersion;
@synthesize lastModified = _lastModified;
@synthesize speciesList = _speciesList;


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
        self.observationSpecVersion = [[RiistaUtils objectOrNilForKey:kBaseClassObservationSpecVersion fromDictionary:dict] doubleValue];
        self.lastModified = [RiistaUtils objectOrNilForKey:kBaseClassLastModified fromDictionary:dict];

        NSObject *receivedSpeciesList = [dict objectForKey:kBaseClassSpeciesList];
        NSMutableArray *parsedSpeciesList = [NSMutableArray array];
        if ([receivedSpeciesList isKindOfClass:[NSArray class]]) {
            for (NSDictionary *item in (NSArray *)receivedSpeciesList) {
                if ([item isKindOfClass:[NSDictionary class]]) {
                    [parsedSpeciesList addObject:[ObservationSpecimenMetadata modelObjectWithDictionary:item]];
                }
            }
        } else if ([receivedSpeciesList isKindOfClass:[NSDictionary class]]) {
            [parsedSpeciesList addObject:[ObservationSpecimenMetadata modelObjectWithDictionary:(NSDictionary *)receivedSpeciesList]];
        }

        self.speciesList = [NSArray arrayWithArray:parsedSpeciesList];
    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:[NSNumber numberWithDouble:self.observationSpecVersion] forKey:kBaseClassObservationSpecVersion];
    [mutableDict setValue:self.lastModified forKey:kBaseClassLastModified];
    NSMutableArray *tempArrayForSpeciesList = [NSMutableArray array];
    for (NSObject *subArrayObject in self.speciesList) {
        if([subArrayObject respondsToSelector:@selector(dictionaryRepresentation)]) {
            // This class is a model object
            [tempArrayForSpeciesList addObject:[subArrayObject performSelector:@selector(dictionaryRepresentation)]];
        } else {
            // Generic object
            [tempArrayForSpeciesList addObject:subArrayObject];
        }
    }
    [mutableDict setValue:[NSArray arrayWithArray:tempArrayForSpeciesList] forKey:kBaseClassSpeciesList];

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

    self.observationSpecVersion = [aDecoder decodeDoubleForKey:kBaseClassObservationSpecVersion];
    self.lastModified = [aDecoder decodeObjectForKey:kBaseClassLastModified];
    self.speciesList = [aDecoder decodeObjectForKey:kBaseClassSpeciesList];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeDouble:_observationSpecVersion forKey:kBaseClassObservationSpecVersion];
    [aCoder encodeObject:_lastModified forKey:kBaseClassLastModified];
    [aCoder encodeObject:_speciesList forKey:kBaseClassSpeciesList];
}

- (id)copyWithZone:(NSZone *)zone
{
    ObservationMetadata *copy = [[ObservationMetadata alloc] init];
    if (copy) {
        copy.observationSpecVersion = self.observationSpecVersion;
        copy.lastModified = [self.lastModified copyWithZone:zone];
        copy.speciesList = [self.speciesList copyWithZone:zone];
    }

    return copy;
}

@end
