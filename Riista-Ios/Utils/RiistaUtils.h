#import <Foundation/Foundation.h>

@class DiaryEntryBase;
@class DiaryImage;

typedef NS_ENUM(NSInteger, PhotoAccessFailureReason);

typedef void(^RiistaDiaryEntryImageLoadCompletion)(UIImage *image);
typedef void(^RiistaImageLoadFailed)(PhotoAccessFailureReason reason);

@interface RiistaUtils : NSObject

/**
 * Returns the object for a key if there's one in the give dict or nil if dict doesn't have a value for the key.
 */
+ (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

+ (NSInteger)startYearFromDate:(NSDate*)date;

+ (NSString*)nameWithPreferredLanguage:(NSDictionary*)nameDictionary;

+ (NSLocale*)appLocale;

+ (NSString*)appVersion;

/* Fixes image rotation for image sending
 * Thanks to: http://blog.logichigh.com/2008/06/05/uiimage-fix/
 * @param imageIn Source image
 * @param limitSize Scale too large images
 * @return Image with corrected orientation
 */
+ (UIImage*)fixImageOrientation:(UIImage*)imageIn limitMaxSize:(BOOL)limitSize;

/**
 * Downscale image to fit max dimensions and return as data
 */
+ (NSData*)imageAsDownscaledData:(UIImage*)image;

/**
 * Downscale image to fit max dimensions and return as image. If the image is not
 * scaled down the argument image is returned unchanged.
 */
+ (UIImage*)imageAsDownscaledImage:(UIImage*)image;

/*
 * Generate colored image
 * @param image color
 * @param width generated image width
 * @param height generated image height
 * @return image with size 1x1 and specified color
 */
+ (UIImage*)imageWithColor:(UIColor*)color width:(CGFloat)width height:(CGFloat)height;

/*
 * Generate id used when sending created new entry to backend
 * 32b epoch time in seconds + 32b pseudo random int
 * @return id
 */
+ (NSNumber*)generateMobileClientRefId;

/*
 * Encode string to URL safe representation.
 * Additionally escaped characters:
 * ":/?#[]@!$&'()%*+,;= "
 *
 * @return encoded string
 */
+ (NSString*)encodeToPercentEscapedString:(NSString*)originalString;

/*
 * Get application data directory
 * Create it if does not exist
 */
+ (NSURL*)applicationDirectory;

/*
 * Equality check which also considers both nil values as equal
 */
+ (BOOL)nilEqual:(id)a b:(id)b;

/*
 * Mark an announcement with the given remote id as unread.
 */
+ (void)addUnreadAnnouncement:(NSNumber*)remoteId;

+ (NSInteger)unreadAnnouncementCount;

+ (void)markAllAnnouncementsAsRead;

/*
 * Return list of decimal number values as NSString. Min and max are inclusive.
 */
+ (NSArray*)decimalRangeAsText:(NSDecimalNumber*)minValue maxValue:(NSDecimalNumber*)maxValue increment:(NSDecimalNumber*)increment;

/* Return the localized string from a dict based on the currently set user locale. */
+(NSString*)getLocalizedString:(NSDictionary*)dict;

@end
