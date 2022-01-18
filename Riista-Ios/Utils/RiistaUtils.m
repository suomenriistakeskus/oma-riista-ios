#import "UIImage+Resize.h"
#import "RiistaUtils.h"
#import "DiaryImage.h"
#import "DiaryEntry.h"
#import "ObservationEntry.h"
#import "RiistaNetworkManager.h"
#import "RiistaGameDatabase.h"
#import "RiistaSettings.h"

#import "Oma_riista-Swift.h"

@implementation RiistaUtils

+ (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}

+ (NSInteger)startYearFromDate:(NSDate*)date
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
    if ([components month] < RiistaCalendarStartMonth) {
        return [components year]-1;
    }
    return [components year];
}

+ (NSString*)nameWithPreferredLanguage:(NSDictionary*)nameDictionary
{
    NSString *preferredLanguage = [RiistaSettings language];
    NSString *name = [nameDictionary objectForKey:preferredLanguage];
    if (name) {
        return [self capitalizeString:name];
    }
    return [self capitalizeString:nameDictionary[RiistaDefaultAppLanguage]];
}

+ (NSString*)capitalizeString:(NSString*)text
{
    return [[[text substringToIndex:1] uppercaseString] stringByAppendingString:[text substringFromIndex:1]];
}

+ (NSLocale*)appLocale
{
    NSString *identifier = [RiistaSettings language];
    return [[NSLocale alloc] initWithLocaleIdentifier:identifier];
}

+ (NSString*)appVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return infoDictionary[(NSString*)kCFBundleVersionKey];
}

+ (UIImage*)fixImageOrientation:(UIImage*)imageIn limitMaxSize:(BOOL)limitSize
{
    if (imageIn == nil) {
        return nil;
    }

    int kMaxResolution = 3264;
    
    CGImageRef        imgRef    = imageIn.CGImage;
    CGFloat           width     = CGImageGetWidth(imgRef);
    CGFloat           height    = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect            bounds    = CGRectMake( 0, 0, width, height );
    
    if (limitSize && (width > kMaxResolution || height > kMaxResolution)) {
        CGFloat ratio = width/height;
        
        if (ratio > 1) {
            bounds.size.width  = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        } else {
            bounds.size.height = kMaxResolution;
            bounds.size.width  = bounds.size.height * ratio;
        }
    }
    
    CGFloat            scaleRatio   = bounds.size.width / width;
    CGSize             imageSize    = CGSizeMake( CGImageGetWidth(imgRef),         CGImageGetHeight(imgRef) );
    UIImageOrientation orient       = imageIn.imageOrientation;
    CGFloat            boundHeight;
    
    switch(orient) {
        case UIImageOrientationUp:                                        //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored:                                //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown:                                      //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored:                              //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored:                              //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft:                                      //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored:                             //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight:                                     //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise: NSInternalInconsistencyException
                        format: @"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext( bounds.size );
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if ( orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    } else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM( context, transform );
    
    CGContextDrawImage( UIGraphicsGetCurrentContext(), CGRectMake( 0, 0, width, height ), imgRef );
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return(imageCopy);
}

+ (NSData*)imageAsDownscaledData:(UIImage*)image
{
    return UIImageJPEGRepresentation([RiistaUtils imageAsDownscaledImage:image], 1.0);
}

+ (UIImage*)imageAsDownscaledImage:(UIImage*)image
{
    if (image.size.width > AppConstants.MaxImageSizeDimen || image.size.height > AppConstants.MaxImageSizeDimen) {
        return [image resizedImageToFitInSize:CGSizeMake(AppConstants.MaxImageSizeDimen, AppConstants.MaxImageSizeDimen)
                               scaleIfSmaller:NO];
    }
    else {
        return image;
    }
}

+ (UIImage*)imageWithColor:(UIColor*)color width:(CGFloat)width height:(CGFloat)height;
{
    CGRect rect = CGRectMake(0.0f, 0.0f, width, height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (NSNumber*)generateMobileClientRefId
{
    NSTimeInterval secondsSinceEpoch = [[NSDate date]timeIntervalSince1970];
    int64_t fullSeconds = secondsSinceEpoch;
    int64_t randomId = (fullSeconds << 32) + arc4random();

    return [NSNumber numberWithLongLong:randomId];
}

+ (NSString*)encodeToPercentEscapedString:(NSString *)originalString
{
    NSCharacterSet *allowedSet = [NSCharacterSet characterSetWithCharactersInString:@":/?#[]@!$&'()%*+,;= "].invertedSet;
    return [originalString stringByAddingPercentEncodingWithAllowedCharacters:allowedSet];
}

+ (NSURL*)applicationDirectory
{
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *dirPath = nil;

    NSArray *appSupportDir = [fm URLsForDirectory:NSApplicationSupportDirectory
                                        inDomains:NSUserDomainMask];
    if ([appSupportDir count] > 0) {
        dirPath = [[appSupportDir objectAtIndex:0] URLByAppendingPathComponent:bundleId];

        NSError *error = nil;
        if (![fm createDirectoryAtURL:dirPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create directory: %@", error);

            return nil;
        }
    }

    return dirPath;
}

+ (BOOL)nilEqual:(id)a b:(id)b
{
    return (a == nil && b == nil) || [a isEqual:b];
}

+ (NSString*)userUnreadAnnouncementsKey
{
    return @"UnreadAnnouncementIds";
}

+ (void)addUnreadAnnouncement:(NSNumber*)remoteId
{
    NSMutableSet* unread = [NSMutableSet new];

    NSArray* stored = [[NSUserDefaults standardUserDefaults] objectForKey:[RiistaUtils userUnreadAnnouncementsKey]];
    if (stored != nil) {
        unread = [[NSMutableSet alloc] initWithArray:stored];
    }
    [unread addObject:remoteId];

    [[NSUserDefaults standardUserDefaults] setObject:[unread allObjects] forKey:[RiistaUtils userUnreadAnnouncementsKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSInteger)unreadAnnouncementCount
{
    NSArray* stored = [[NSUserDefaults standardUserDefaults] objectForKey:[RiistaUtils userUnreadAnnouncementsKey]];
    if (stored != nil) {
        return [stored count];
    }
    return 0;
}

+ (void)markAllAnnouncementsAsRead
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray new] forKey:[RiistaUtils userUnreadAnnouncementsKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray*)decimalRangeAsText:(NSDecimalNumber*)minValue maxValue:(NSDecimalNumber*)maxValue increment:(NSDecimalNumber*)increment
{
    NSMutableArray *list = [NSMutableArray new];

    for (NSDecimalNumber *value = minValue; [value compare:maxValue] != NSOrderedDescending; value = [value decimalNumberByAdding:increment]) {
        [list addObject:[value stringValue]];
    }

    return list;
}

+ (NSString*)getLocalizedString:(NSDictionary*)dict
{
    NSString *result = [dict objectForKey:[RiistaSettings language]];
    if (result == nil) {
        result = [dict objectForKey:@"fi"]; //Fallback
    }

    if (result == nil || result.length == 0) {
        result = @"";
    }
    return result;
}

@end
