#import "RiistaSettings.h"
#import "RiistaMmlTileLayer.h"

NSString *const RefererKey = @"Referer";
NSString *const RefererValue = @"https://oma.riista.fi";
NSString *const MmlTopographicTileUrlFormat = @"http://kartta.riista.fi/tms/1.0.0/maasto_mobile/EPSG_3857/%u/%u/%u.png";
NSString *const MmlAerialTileUrlFormat = @"http://kartta.riista.fi/tms/1.0.0/orto_mobile/EPSG_3857/%u/%u/%u.png";
NSString *const MmlBackgroundTileUrlFormat = @"http://kartta.riista.fi/tms/1.0.0/tausta_mobile/EPSG_3857/%u/%u/%u.png";

NSInteger const tileHeight = 256;
NSInteger const tileWidth = 256;


@interface RiistaMmlTileLayer ()

@property NSString *urlFormat;

@end


@implementation RiistaMmlTileLayer

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.urlFormat = MmlTopographicTileUrlFormat;
        [self setupTileSize];
    }
    return self;
}

- (void)setupTileSize
{
    int screenScale = round(UIScreen.mainScreen.scale);

    // the default tileSize available on the server is 256x256. There's no point in rendering
    // in smaller size. Also prevent rendering tiles as too large as this would cause tiles to blur
    //
    // this setting can be used as "map zoom" i.e. to help make texts more readable.
    // - we could e.g. add a setting to UI ('easy to read map on/off') and we could add e.g. 128
    //   to the extraZoom based on that value

    // not really zoom but helps keeping current tile zoom level bit further when zooming in.
    // This prevents displaying next zoom levels before their texts become readable
    int extraZoom = 128;
    int tileHeight = MIN(MAX(128 * screenScale, 256) + extraZoom, 512);
    self.tileSize = tileHeight;
    DDLog(@"Will use %dx%d tilesize", tileHeight, tileHeight);
}

- (void)setMapType:(RiistaMapType)type
{
    NSString *oldFormat = self.urlFormat;

    if (type == MmlAerialMapType) {
        self.urlFormat = MmlAerialTileUrlFormat;
    }
    else if (type == MmlBackgroundMapType) {
        self.urlFormat = MmlBackgroundTileUrlFormat;
    }
    else {
        self.urlFormat = MmlTopographicTileUrlFormat;
    }

    if (![oldFormat isEqualToString:self.urlFormat]) {
        [self clearTileCache];
    }
}

- (NSURL *)getTileUrl:(NSUInteger)x y:(NSUInteger)y zoom:(NSUInteger)zoom
{
    NSString *tileUrl = [NSString stringWithFormat:self.urlFormat, zoom, x, [self tmsConvert:y zoom:zoom]];

    return [NSURL URLWithString:tileUrl];
}

- (NSInteger)tmsConvert:(NSUInteger)y zoom:(NSUInteger)zoom
{
    return (1 << zoom) - y - 1;
}

- (void)requestTileForX:(NSUInteger)x y:(NSUInteger)y zoom:(NSUInteger)zoom receiver:(id<GMSTileReceiver>)receiver
{
    NSURL *url = [self getTileUrl:x y:y zoom:zoom];

    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url];
    [mutableRequest addValue:RefererValue forHTTPHeaderField:RefererKey];

    NSURLRequest *request = [mutableRequest copy];

    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            //Try again later
            [receiver receiveTileWithX:x y:y zoom:zoom image:nil];
        }
        else {
            UIImage *image = [UIImage imageWithData:data];
            [receiver receiveTileWithX:x y:y zoom:zoom image:image];
        }
    }] resume];
}

@end
