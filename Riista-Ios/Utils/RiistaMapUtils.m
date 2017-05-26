#import "RiistaMapUtils.h"

NSInteger const GOOD_ACCURACY_IN_METERS = 30;
NSInteger const AVERAGE_ACCURACY_IN_METERS = 80;

@implementation RiistaMapUtils
{
    double Ca, Cb, Cf, Ck0, Clo0, CE0, Cn, CA1, Ce, Ch1, Ch2, Ch3, Ch4, Ch1p, Ch2p, Ch3p, Ch4p;
}

+ (RiistaMapUtils*)sharedInstance
{
    static RiistaMapUtils *pInst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pInst = [RiistaMapUtils new];
    });
    return pInst;
}

- (id)init
{
    self = [super init];
    if (self) {
        Ca = 6378137.0;
        Cb = 6356752.314245;
        Cf = 1.0 / 298.257223563;
        Ck0 = 0.9996;
        Clo0 = (27.0 * M_PI / 180.0);
        CE0 = 500000.0;
        Cn = Cf / (2.0 - Cf);
        CA1 = Ca / (1.0 + Cn) * (1.0 + pow(Cn, 2.0) / 4.0 + pow(Cn, 4) / 64.0);
        Ce = sqrt(2.0 * Cf - pow(Cf, 2));
        Ch1 = 1.0/2.0 * Cn - 2.0/3.0 * pow(Cn, 2.0) + 37.0/96.0 * pow(Cn, 3.0) - 1.0/360.0 * pow(Cn, 4.0);
        Ch2 = 1.0/48.0 * pow(Cn, 2) + 1.0/15.0 * pow(Cn, 3) - 437.0/1440.0 * pow(Cn, 4);
        Ch3 = 17.0/480.0 * pow(Cn, 3) - 37.0/840.0 * pow(Cn, 4);
        Ch4 = 4397.0/161280.0 * pow(Cn, 4);
        Ch1p = 1.0/2.0 * Cn - 2.0/3.0 * pow(Cn, 2) + 5.0/16.0 * pow(Cn, 3) + 41.0/180.0 * pow(Cn, 4);
        Ch2p = 13.0/48.0 * pow(Cn, 2) - 3.0/5.0 * pow(Cn, 3) + 557.0/1440.0 * pow(Cn, 4);
        Ch3p = 61.0/240.0 * pow(Cn, 3) - 103.0/140.0 * pow(Cn, 4);
        Ch4p = 49561.0/161280.0 * pow(Cn, 4);
    }
    return self;
}

- (ETRMSPair*)WGS84toETRSTM35FIN:(double)latitude longitude:(double)longitude
{
    double la = [RiistaMapUtils deg2rad:latitude];
    double lo = [RiistaMapUtils deg2rad:longitude];
    double Q = asinh(tan(la)) - Ce * atanh(Ce * sin(la));
    double be = atan(sinh(Q));
    double nnp = atanh(cos(be) * sin(lo - Clo0));
    double Ep = asin(sin(be) * cosh(nnp));
    double E1 = Ch1p * sin(2.0 * Ep) * cosh(2.0 * nnp);
    double E2 = Ch2p * sin(4.0 * Ep) * cosh(4.0 * nnp);
    double E3 = Ch3p * sin(6.0 * Ep) * cosh(6.0 * nnp);
    double E4 = Ch4p * sin(8.0 * Ep) * cosh(8.0 * nnp);
    double nn1 = Ch1p * cos(2.0 * Ep) * sinh(2.0 * nnp);
    double nn2 = Ch2p * cos(4.0 * Ep) * sinh(4.0 * nnp);
    double nn3 = Ch3p * cos(6.0 * Ep) * sinh(6.0 * nnp);
    double nn4 = Ch4p * cos(8.0 * Ep) * sinh(8.0 * nnp);
    double E = Ep + E1 + E2 + E3 + E4;
    double nn = nnp + nn1 + nn2 + nn3 + nn4;
    long etrs_x = (long)(CA1 * E * Ck0);
    long etrs_y = (long)(CA1 * nn * Ck0 + CE0);
    ETRMSPair *pair = [ETRMSPair new];
    pair.x = etrs_x;
    pair.y = etrs_y;
    return pair;
}

- (WGS84Pair*)ETRMStoWGS84:(long)etrs_x y:(long) etrs_y
{
    double E = etrs_x / (CA1 * Ck0);
    double nn = (etrs_y - CE0) / (CA1 * Ck0);
    double E1p = Ch1 * sin(2.0 * E) * cosh(2.0 * nn);
    double E2p = Ch2 * sin(4.0 * E) * cosh(4.0 * nn);
    double E3p = Ch3 * sin(6.0 * E) * cosh(6.0 * nn);
    double E4p = Ch4 * sin(8.0 * E) * cosh(8.0 * nn);
    double nn1p = Ch1 * cos(2.0 * E) * sinh(2.0 * nn);
    double nn2p = Ch2 * cos(4.0 * E) * sinh(4.0 * nn);
    double nn3p = Ch3 * cos(6.0 * E) * sinh(6.0 * nn);
    double nn4p = Ch4 * cos(8.0 * E) * sinh(8.0 * nn);
    double Ep = E - E1p - E2p - E3p - E4p;
    double nnp = nn - nn1p - nn2p - nn3p - nn4p;
    double be = asin(sin(Ep) / cosh(nnp));
    double Q = asinh(tan(be));
    double Qp = Q + Ce * atanh(Ce * tanh(Q));
    Qp = Q + Ce * atanh(Ce * tanh(Qp));
    Qp = Q + Ce * atanh(Ce * tanh(Qp));
    Qp = Q + Ce * atanh(Ce * tanh(Qp));
    double latitude = [RiistaMapUtils rad2deg:atan(sinh(Qp))];
    double longitude = [RiistaMapUtils rad2deg:(Clo0 + asin(tanh(nnp) / cos(be)))];
    WGS84Pair *pair = [WGS84Pair new];
    pair.x = latitude;
    pair.y = longitude;
    return pair;
}

+ (double)asinh:(double)x
{
    return log(x + sqrt(x*x + 1.0));
}

+ (double)acosh:(double)x
{
    return log(x + sqrt(x*x - 1.0));
}

+ (double)atanh:(double)x {
    return 0.5*log( (x + 1.0) / (1.0 - x) );
}

+ (double)deg2rad:(double)deg
{
    return (deg * M_PI / 180.0);
}

+ (double)rad2deg:(double)rad
{
    return (rad * 180) / M_PI;
}

@end

@implementation WGS84Pair
@end

@implementation ETRMSPair
@end
