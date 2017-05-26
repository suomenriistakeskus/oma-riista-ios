#import <Foundation/Foundation.h>

/**
 * Finnish hunting permit number is for example 2013-3-450-00260-2, where
 * <ul>
 * <li>2013: year when permit is given, 4 digits</li>
 * <li>3: how many years permit is valid, 1,2,3,4 or 5</li>
 * <li>450: RKA code, zero padded to 3 digits</li>
 * <li>00260: running permit number counter, zero padded to 5 digits</li>
 * <li>2: checksum, calculated just as finnish creditor reference (suomalainen viitenumero)</li>
 * </ul>
 */
@interface FinnishHuntingPermitNumberValidator : NSObject

+ (BOOL)validate:(NSString*)value verifyChecksum:(BOOL)verifyChecksum;
+ (char)calculateChecksum:(NSString*)s;

@end
