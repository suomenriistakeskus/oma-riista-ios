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
    }
    return self;
}

- (void)setMapType:(RiistaMapType)type
{
    if (type == MmlAerialMapType) {
        self.urlFormat = MmlAerialTileUrlFormat;
    }
    else if (type == MmlBackgroundMapType) {
        self.urlFormat = MmlBackgroundTileUrlFormat;
    }
    else {
        self.urlFormat = MmlTopographicTileUrlFormat;
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

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

                               if (connectionError) {
                                   [receiver receiveTileWithX:x y:y zoom:zoom image:kGMSTileLayerNoTile];
                               }
                               else {
                                   UIImage *image = [UIImage imageWithData:data];
                                   [receiver receiveTileWithX:x y:y zoom:zoom image:image];
                               }
                           } ];
}

@end
