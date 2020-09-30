
#import "RiistaVectorUtils.h"

@implementation RiistaLinearRing

- (id)initWithSize:(NSUInteger)size
{
    self = [super init];
    if (self) {
        _size = size;
        _coords = [NSMutableArray new];
        for (NSUInteger i = 0; i < size * 2; i++) {
            [_coords addObject:[NSNumber numberWithInteger:0]];
        }
    }
    return self;
}

- (NSInteger)getX:(NSInteger)index
{
    return [[_coords objectAtIndex:2 * index] integerValue];
}

- (NSInteger)getY:(NSInteger)index
{
    return [[_coords objectAtIndex:2 * index + 1] integerValue];
}

- (void)set:(NSInteger)index :(NSInteger)x :(NSInteger)y;
{
    [_coords replaceObjectAtIndex:(2 * index) withObject:[NSNumber numberWithInteger:x]];
    [_coords replaceObjectAtIndex:(2 * index + 1) withObject:[NSNumber numberWithInteger:y]];
}

- (NSInteger)signedArea
{
    NSInteger sum = 0;

    NSInteger i = 0;
    NSInteger j = _size - 1;
    for (; i < _size; j = i++) {
        sum += ([self getX:j] - [self getX:i]) * ([self getY:i] + [self getY:j]);
    }
    return sum;
}

@end

@implementation RiistaMvtCursor

-(id)init
{
    if (self = [super init])  {
        _x = 0;
        _y = 0;
    }
    return self;
}

- (void)reset
{
    _x = 0;
    _y = 0;
}
- (void)decodeMoveTo:(uint32_t)rx :(uint32_t)ry
{
    _x += [self zigZagDecode:rx];
    _y += [self zigZagDecode:ry];
}

- (int32_t)zigZagDecode:(uint32_t)n
{
    return (n >> 1) ^ (-(n & 1));
}

@end

@implementation RiistaPolygon

- (id)initWithOuterRing:(RiistaLinearRing*)ring
{
    self = [super init];
    if (self) {
        _outerRing = ring;
        _innerRings = [NSMutableArray new];
    }
    return self;
}

- (void)addInnerRing:(RiistaLinearRing*)ring
{
    [_innerRings addObject:ring];
}

@end
