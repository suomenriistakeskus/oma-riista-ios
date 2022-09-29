
#import "RiistaVectorTileLayer.h"
#import "RiistaNetworkManager.h"
#import "Vectortile.pbobjc.h"
#import "RiistaVectorUtils.h"
#import "Oma_riista-Swift.h"

const NSInteger TILE_SIZE = 256;

NSString *const MooseTileUrlFormat = @"https://kartta.riista.fi/vector/hirvi/%lu/%lu/%lu";
NSString *const PienriistaTileUrlFormat = @"https://kartta.riista.fi/vector/pienriista/%lu/%lu/%lu";
NSString *const ValtionmaaTileUrlFormat = @"https://kartta.riista.fi/vector/metsahallitus/%lu/%lu/%lu";
NSString *const RhyTileUrlFormat = @"https://kartta.riista.fi/vector/rhy/%lu/%lu/%lu";
NSString *const GameTrianglesFormat = @"https://kartta.riista.fi/vector/riistakolmiot/%lu/%lu/%lu";
NSString *const MooseRestrictionsFormat = @"https://kartta.riista.fi/vector/hirvi_rajoitusalueet/%lu/%lu/%lu";
NSString *const SmallGameRestrictionsFormat = @"https://kartta.riista.fi/vector/pienriista_rajoitusalueet/%lu/%lu/%lu";
NSString *const AviHuntingBanFormat = @"https://kartta.riista.fi/vector/avi_metsastyskieltoalueet/%lu/%lu/%lu";

NSString *const AreaNameKey = @"KOHDE_NIMI";

@interface RiistaVectorTileLayer ()

// really AppConstants.AreaType
@property(nonatomic, assign) NSInteger areaType;
@property(atomic, strong) NSString *externalAreaId;
@property BOOL invertAreaColors;

@end

@implementation RiistaVectorTileLayer
{
    TileCache* tileCache;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        _externalAreaId = nil;
        _invertAreaColors = NO;
        tileCache = [[TileCacheProvider shared] getCacheWithType:CacheTypeVectorTiles];
    }
    return self;
}

- (void)setExternalId:(NSString*)externalId
{
    if ([self.externalAreaId isEqualToString:externalId]) {
        return;
    }

    self.externalAreaId = externalId;
    [self clearTileCache];
}

- (void)setInvertColors:(BOOL)invert
{
    if (self.invertAreaColors == invert) {
        return;
    }

    self.invertAreaColors = invert;
    [self clearTileCache];
}

- (NSString*)getCacheKeyDiscriminator
{
    // discriminate tiles based on whether colors have been inverted or not
    // -> allows storing multiple images for same x-y-zoom combination
    if (self.invertAreaColors) {
        return @"area-colors-inverted";
    } else {
        return @"normal-area-colors";
    }
}

- (NSString *)getTileUrlString:(NSUInteger)x y:(NSUInteger)y zoom:(NSUInteger)zoom
{
    NSString *base = [RiistaNetworkManager getBaseApiPath];
    NSString *api;
    NSString *tileUrl;

    switch (self.areaType) {
        case AreaTypeMoose:
            tileUrl = [NSString stringWithFormat:MooseTileUrlFormat, (unsigned long)zoom, (unsigned long)x, (unsigned long)y];
            break;
        case AreaTypePienriista:
            tileUrl = [NSString stringWithFormat:PienriistaTileUrlFormat, (unsigned long)zoom, (unsigned long)x, (unsigned long)y];
            break;
        case AreaTypeValtionmaa:
            tileUrl = [NSString stringWithFormat:ValtionmaaTileUrlFormat, (unsigned long)zoom, (unsigned long)x, (unsigned long)y];
            break;
        case AreaTypeRhy:
            tileUrl = [NSString stringWithFormat:RhyTileUrlFormat, (unsigned long)zoom, (unsigned long)x, (unsigned long)y];
            break;
        case AreaTypeGameTriangles:
            tileUrl = [NSString stringWithFormat:GameTrianglesFormat, (unsigned long)zoom, (unsigned long)x, (unsigned long)y];
            break;
        case AreaTypeSeura:
            api = [NSString stringWithFormat:@"https://%@%@", base, @"area/vector/%@/%u/%u/%u"];
            tileUrl = [NSString stringWithFormat:api, self.externalAreaId, zoom, x, y];
            break;
        case AreaTypeMooseRestrictions:
            tileUrl = [NSString stringWithFormat:MooseRestrictionsFormat, (unsigned long)zoom, (unsigned long)x, (unsigned long)y];
            break;
        case AreaTypeSmallGameRestrictions:
            tileUrl = [NSString stringWithFormat:SmallGameRestrictionsFormat, (unsigned long)zoom, (unsigned long)x, (unsigned long)y];
            break;
        case AreaTypeAviHuntingBan:
            tileUrl = [NSString stringWithFormat:AviHuntingBanFormat, (unsigned long)zoom, (unsigned long)x, (unsigned long)y];
            break;
        default:
            break;
    }

    return tileUrl;
}

- (void)requestTileForX:(NSUInteger)x y:(NSUInteger)y zoom:(NSUInteger)zoom receiver:(id<GMSTileReceiver>)receiver
{
    if (self.externalAreaId == nil || self.externalAreaId.length == 0) {
        [receiver receiveTileWithX:x y:y zoom:zoom image:nil];
        return;
    }

    NSString *tileUrlString = [self getTileUrlString:x y:y zoom:zoom];

    [tileCache retrieveTileWithTileUrl:tileUrlString
                      keyDiscriminator:[self getCacheKeyDiscriminator]
                            completion:^(UIImage * _Nullable image) {
        if (image != nil) {
            [receiver receiveTileWithX:x y:y zoom:zoom image:image];
        } else {
            [self fetchAndProcessVectorTile:tileUrlString x:x y:y zoom:zoom receiver:receiver];
        }
    }];
}

- (void)fetchAndProcessVectorTile:(NSString*)urlString x:(NSUInteger)x y:(NSUInteger)y zoom:(NSUInteger)zoom receiver:(id<GMSTileReceiver>)receiver
{
    NSURL *tileUrl = [NSURL URLWithString:urlString];

    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:tileUrl];
    mutableRequest.cachePolicy = NSURLRequestReloadRevalidatingCacheData;
    //[mutableRequest addValue:RefererValue forHTTPHeaderField:RefererKey];

    NSURLRequest *request = [mutableRequest copy];
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [receiver receiveTileWithX:x y:y zoom:zoom image:nil];
        }
        else {
            dispatch_queue_t tileQueue = dispatch_queue_create("fi.riistakeskus.riista",NULL);
            dispatch_async(tileQueue, ^{
                __block UIImage *image = [self processImage:data];

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (image && self.areaType == AreaTypeSeura && self->_invertAreaColors) {
                        image = [self invertImage:image];
                    }
                    [self->tileCache storeTileWithTileUrl:urlString
                                                     tile:image
                                                 tileData:data
                                         keyDiscriminator:[self getCacheKeyDiscriminator]];
                    [receiver receiveTileWithX:x y:y zoom:zoom image:image];
                });
            });
        }
    }] resume];
}

- (UIImage*)invertImage:(UIImage*)image
{
    const CGSize size = image.size;
    const int width = size.width;
    const int height = size.height;

    //Create a suitable RGB+alpha bitmap context in BGRA colour space
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *memoryPool = (unsigned char *)calloc(width*height*4, 1);
    CGContextRef context = CGBitmapContextCreate(memoryPool, width, height, 8, width * 4, colourSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colourSpace);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);

    for (int y = 0; y < height; y++) {
        unsigned char *rgba = &memoryPool[y * width * 4];

        for (int x = 0; x < width; x++) {
            if (rgba[3] == 0) {
                //Outside, set to red
                rgba[0] = 255;
                rgba[3] = 64;
            }
            else if (rgba[0] + rgba[1] + rgba[2] < 50) {
                //Border, do nothing
            }
            else {
                //Inside, make transparent
                rgba[3] = 0;
            }
            rgba += 4;
        }
    }

    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *returnImage = [UIImage imageWithCGImage:cgImage];

    CGImageRelease(cgImage);
    CGContextRelease(context);
    free(memoryPool);

    return returnImage;
}

- (UIImage*)processImage:(NSData*)data
{
    CGRect rect = CGRectMake(0, 0, TILE_SIZE, TILE_SIZE);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    RiistaMvtCursor *cursor = [RiistaMvtCursor new];
    Tile *tile = [Tile parseFromData:data error:nil];

    if (tile && tile.layersArray_Count > 0) {
        NSUInteger count = [tile layersArray_Count];
        for (int i = 0; i < count; i++) {
            Tile_Layer *layer = tile.layersArray[i];
            const float scale = TILE_SIZE / (float)layer.extent;
            const NSUInteger featureCount = [layer featuresArray_Count];

            for (int x = 0; x < featureCount; x++) {
                Tile_Feature *feature = layer.featuresArray[x];

                // Filter out features belonging to non-selected areas
                if ((self.areaType == AreaTypeMoose || self.areaType == AreaTypePienriista) && [self skipFeatureRender:layer :feature]) {
                    continue;
                }

                [cursor reset];

                if (feature.type == Tile_GeomType_Polygon) {
                    NSMutableArray<RiistaLinearRing*> *rings = [self decodeRings:feature.geometryArray :cursor];
                    NSMutableArray<RiistaPolygon*> *polys = [self decodePolygons:rings];

                    for (int j = 0; j < polys.count; j++) {
                        RiistaPolygon *poly = [polys objectAtIndex:j];

                        CGContextSaveGState(context);
                        [self drawPolygon:poly :context :scale];
                        CGContextRestoreGState(context);
                    }
                }
            }
        }
    }

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return img;
}

- (BOOL)skipFeatureRender:(Tile_Layer*)layer :(Tile_Feature*)feature
{
    if (layer == nil || feature == nil || layer.keysArray == nil || layer.valuesArray == nil || feature.tagsArray == nil) {
        DDLog(@"Tile content incomplete");
        return YES;
    }

    BOOL matchesExternalId = NO;

    for (int i = 0; i < feature.tagsArray_Count - 1; i += 2) {
        NSUInteger keyIndex = [feature.tagsArray valueAtIndex:i];
        NSUInteger valIndex = [feature.tagsArray valueAtIndex:(i + 1)];

        BOOL valid = keyIndex < layer.keysArray_Count && valIndex < layer.valuesArray_Count;

        if (valid &&
            [AreaNameKey isEqualToString:layer.keysArray[keyIndex]] &&
            layer.valuesArray[valIndex] != nil &&
            layer.valuesArray[valIndex].stringValue != nil) {
            if ([layer.valuesArray[valIndex].stringValue hasPrefix:self.externalAreaId]) {
                matchesExternalId = YES;
                break;
            }
        }
    }

    return !matchesExternalId;
}

- (void)drawPolygon:(RiistaPolygon*)polygon :(CGContextRef)context :(float)scale
{
    CGContextScaleCTM(context, scale, scale);

    UIBezierPath *path = [UIBezierPath new];

    [path moveToPoint:CGPointMake([polygon.outerRing getX:0], [polygon.outerRing getY:0])];
    for (int i = 1; i < [polygon.outerRing size]; i++) {
        [path addLineToPoint:CGPointMake([polygon.outerRing getX:i], [polygon.outerRing getY:i])];
    }

    if (polygon.innerRings) {
        for (int r = 0; r < polygon.innerRings.count; r++) {
            RiistaLinearRing *ring = [polygon.innerRings objectAtIndex:r];
            [path moveToPoint:CGPointMake([ring getX:0], [ring getY:0])];

            for (int i = 1; i < [ring size]; i++) {
                [path addLineToPoint:CGPointMake([ring getX:i], [ring getY:i])];
            }
        }
    }

    [self setFillColor:context];
    [self setBorderColor:context];

    [path setUsesEvenOddFillRule:YES];
    [path setLineWidth:(1.0f / scale) * 2.0f];
    [path fill];
    [path stroke];
}

- (void)setFillColor:(CGContextRef)context
{
    switch (self.areaType) {
        case AreaTypeMoose:
            CGContextSetRGBFillColor(context, 0.0, (CGFloat)128/255, (CGFloat)128/255, (CGFloat)64/255);
            break;
        case AreaTypePienriista:
            CGContextSetRGBFillColor(context, (CGFloat)128/255, (CGFloat)128/255, 0.0, (CGFloat)64/255);
            break;
        case AreaTypeValtionmaa:
            CGContextSetRGBFillColor(context, 0.0, 0.0, 1, (CGFloat)64/255);
            break;
        case AreaTypeRhy:
            CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.0);
            break;
        case AreaTypeGameTriangles:
            CGContextSetRGBFillColor(context, 1, 0, 0, (CGFloat)64/255);
            break;
        case AreaTypeMooseRestrictions:
            CGContextSetRGBFillColor(context, 1, 0, 0, (CGFloat)64/255);
            break;
        case AreaTypeSmallGameRestrictions:
            CGContextSetRGBFillColor(context, 1, 0, 0, (CGFloat)64/255);
            break;
        case AreaTypeAviHuntingBan:
            CGContextSetRGBFillColor(context, 1, 0, 0, (CGFloat)64/255);
            break;
        default:
            CGContextSetRGBFillColor(context, 0.0, 0.75, 0.0, 0.3);
            break;
    }
}

- (void)setBorderColor:(CGContextRef)context
{
    switch (self.areaType) {
        case AreaTypeRhy:
            CGContextSetRGBStrokeColor(context, 0.0, 0.0, 1, 0.9);
            break;
        default:
            CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0, 0.9);
            break;
    }
}

#define CMD_MOVE_TO 1
#define CMD_LINE_TO 2
#define CMD_CLOSE_PATH 7

- (NSMutableArray<RiistaLinearRing*>*)decodeRings:(GPBUInt32Array*)input :(RiistaMvtCursor*)cursor
{
    NSMutableArray<RiistaLinearRing*> *rings = [NSMutableArray new];
    if (input == nil || input.count == 0) {
        return rings;
    }

    NSInteger i = 0;
    uint32_t cmd = 0;
    uint32_t cmdLength = 0;

    while (i <= input.count - 9) {
        cmd = [input valueAtIndex:i++];
        cmdLength = cmd >> 3;

        if ((cmd & 0x7) != CMD_MOVE_TO || cmdLength != 1) {
            break;
        }

        [cursor decodeMoveTo:[input valueAtIndex:i] :[input valueAtIndex:(i + 1)]];
        i += 2;

        cmd = [input valueAtIndex:i++];
        cmdLength = cmd >> 3;

        if ((cmd & 0x7) != CMD_LINE_TO || cmdLength < 2) {
            break;
        }

        if (((cmdLength * 2) + i + 1 ) > input.count) {
            break;
        }

        RiistaLinearRing *linearRing = [[RiistaLinearRing alloc] initWithSize:cmdLength + 2];
        [linearRing set:0 :cursor.x :cursor.y];

        for (NSInteger lineToIndex = 0; lineToIndex < cmdLength; ++lineToIndex) {
            [cursor decodeMoveTo:[input valueAtIndex:i] :[input valueAtIndex:(i + 1)]];
            i += 2;
            [linearRing set:lineToIndex + 1 :cursor.x :cursor.y];
        }

        cmd = [input valueAtIndex:i++];
        cmdLength = cmd >> 3;

        if ((cmd & 0x7) != CMD_CLOSE_PATH || cmdLength != 1) {
            break;
        }

        //Close path
        [linearRing set:[linearRing size] - 1: [linearRing getX:0]: [linearRing getY:0]];
        [rings addObject:linearRing];
    }

    return rings;
}

- (NSMutableArray<RiistaPolygon*>*)decodePolygons:(NSMutableArray<RiistaLinearRing*>*)input
{
    NSMutableArray<RiistaPolygon*> *polygons = [NSMutableArray new];
    if (input.count == 0) {
        return polygons;
    }

    if (input.count == 1) {
        RiistaLinearRing *ring = [input objectAtIndex:0];
        RiistaPolygon *singlePolygon = [[RiistaPolygon alloc] initWithOuterRing:ring];
        [polygons addObject:singlePolygon];

        return polygons;
    }

    RiistaPolygon *polygon = nil;
    NSNumber *ccw = nil;

    for (RiistaLinearRing *linearRing in input) {
        long area = [linearRing signedArea];

        if (area == 0) {
            continue;
        }

        if (ccw == nil) {
            ccw = [NSNumber numberWithBool:(area < 0)];
        }

        if ([ccw boolValue] == (area < 0)) {
            if (polygon != nil) {
                [polygons addObject:polygon];
            }
            polygon = [[RiistaPolygon alloc] initWithOuterRing:linearRing];
        }
        else {
            [polygon addInnerRing:linearRing];
        }
    }

    if (polygon != nil) {
        [polygons addObject:polygon];
    }

    return polygons;
}

@end
