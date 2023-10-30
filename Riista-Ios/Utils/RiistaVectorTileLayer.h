#import <GoogleMaps/GoogleMaps.h>
#import <Foundation/Foundation.h>

@class RiistaCommonMapTileVersions;

@interface RiistaVectorTileLayer : GMSTileLayer

- (instancetype)initWithMapTileVersions:(RiistaCommonMapTileVersions *)mapTileVersionProvider;

- (void)setExternalId:(NSString*)externalId;
- (void)setInvertColors:(BOOL)invert;
// areaType is really AppConstants.AreaType but since this function needs to be accessed from
// Swift we cannot currently use enums here
- (void)setAreaType:(NSInteger)areaType;

@end
