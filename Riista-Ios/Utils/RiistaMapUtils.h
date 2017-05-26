#import <Foundation/Foundation.h>

extern NSInteger const GOOD_ACCURACY_IN_METERS;
extern NSInteger const AVERAGE_ACCURACY_IN_METERS;

@interface ETRMSPair : NSObject

@property (nonatomic, assign) NSInteger x;
@property (nonatomic, assign) NSInteger y;

@end

@interface WGS84Pair : NSObject

@property (nonatomic, assign) double x;
@property (nonatomic, assign) double y;

@end

@interface RiistaMapUtils : NSObject

+ (RiistaMapUtils*)sharedInstance;

- (ETRMSPair*)WGS84toETRSTM35FIN:(double)latitude longitude:(double)longitude;

- (WGS84Pair*)ETRMStoWGS84:(long)etrs_x y:(long) etrs_y;

@end
