#import <GoogleMaps/GoogleMaps.h>
#import <Foundation/Foundation.h>
#import "Oma_riista-Swift.h"

@interface RiistaVectorTileLayer : GMSTileLayer

- (void)setExternalId:(NSString*)externalId;
- (void)setInvertColors:(BOOL)invert;
- (void)setAreaType:(AreaType)areaType;

@end
