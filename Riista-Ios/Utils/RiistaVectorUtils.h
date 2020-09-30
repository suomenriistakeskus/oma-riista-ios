
#import <Foundation/Foundation.h>

@interface RiistaLinearRing : NSObject
@property(atomic) NSUInteger size;
@property(atomic, strong) NSMutableArray<NSNumber*> *coords;

- (id)initWithSize:(NSUInteger)size;
- (NSInteger)getX:(NSInteger)index;
- (NSInteger)getY:(NSInteger)index;
- (void)set:(NSInteger)index :(NSInteger)x :(NSInteger)y;
- (NSInteger)signedArea;
@end

@interface RiistaMvtCursor : NSObject
@property(atomic) int32_t x;
@property(atomic) int32_t y;

- (id)init;
- (void)reset;
- (void)decodeMoveTo:(uint32_t)rx :(uint32_t)ry;
- (int32_t)zigZagDecode:(uint32_t)n;
@end

@interface RiistaPolygon : NSObject
@property(atomic, strong) RiistaLinearRing *outerRing;
@property(atomic, strong) NSMutableArray<RiistaLinearRing*> *innerRings;

- (id)initWithOuterRing:(RiistaLinearRing*)ring;
- (void)addInnerRing:(RiistaLinearRing*)ring;
@end
