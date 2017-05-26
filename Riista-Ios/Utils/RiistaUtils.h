#import <Foundation/Foundation.h>

@class DiaryEntryBase;
@class DiaryImage;

typedef void(^RiistaDiaryEntryImageLoadCompletion)(UIImage *image);

@interface RiistaUtils : NSObject

+ (NSInteger)startYearFromDate:(NSDate*)date;

+ (NSString*)nameWithPreferredLanguage:(NSDictionary*)nameDictionary;

/**
 * Loads appropriate thumbnail image for given event
 * If event has images added into it, first image is used
 * If no images have been added, species image is used instead
 * @param entry DiaryEntry object
 * @param forImageView target imageview
 * @param completion Completion block, can be used for caching
 */
+ (void)loadEventImage:(DiaryEntryBase*)entry forImageView:(UIImageView*)imageView completion:(RiistaDiaryEntryImageLoadCompletion)completion;

/**
 * Loads local/remote image using given DiaryImage object
 * @param image DiaryImage object
 * @param forImageView target imageview
 * @param completion Completion block
 */
+ (void)loadDiaryImage:(DiaryImage*)image forImageView:(UIImageView*)imageView completion:(RiistaDiaryEntryImageLoadCompletion)completion;

/*
 * Loads local/remote image using given DiaryImage object
 * @param image DiaryImage object
 * @param size
 * @param completion Completion block
 */
+ (void)loadDiaryImage:(DiaryImage*)image size:(CGSize)size completion:(RiistaDiaryEntryImageLoadCompletion)completion;

/**
 * Loads local image from given uri.
 * @param uri Uri string
 * @param fullSize if true, full image resolution is used
 * @param fixRotation Used with UIImageJPEGRepresentation
 * @param completion Completion block
 */
+ (void)loadImagefromLocalUri:(NSString*)uri fullSize:(BOOL)fullsize fixRotation:(BOOL)fixRotation completion:(RiistaDiaryEntryImageLoadCompletion)completion;

+ (UIImage*)scaleImage:(UIImage*)image toSize:(CGSize)size;

/**
 * Tries to load species image for given species id
 * If image cannot be found, placeholder icon is used instead
 */
+ (UIImage*)loadSpeciesImage:(NSInteger)gameSpeciesCode;

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
 * :/?#[]@!$&'()*+,;=
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

@end
