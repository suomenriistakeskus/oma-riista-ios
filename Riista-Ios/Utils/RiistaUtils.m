#import <AssetsLibrary/AssetsLibrary.h>
#import <UIImage+Resize.h>
#import "RiistaUtils.h"
#import "DiaryImage.h"
#import "RiistaDiaryImageManager.h"
#import "DiaryEntry.h"
#import "ObservationEntry.h"
#import "RiistaNetworkManager.h"
#import "RiistaGameDatabase.h"
#import "RiistaSettings.h"

@implementation RiistaUtils

+ (NSInteger)startYearFromDate:(NSDate*)date
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
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

+ (void)loadEventImage:(DiaryEntryBase*)entry forImageView:(UIImageView*)imageView completion:(RiistaDiaryEntryImageLoadCompletion)completion
{
    NSSet *entryImages;
    NSInteger entrySpeciesCode;

    if ([entry class] == [ObservationEntry class]) {
        ObservationEntry *item = (ObservationEntry*)entry;
        entryImages = [item.diaryImages set];
        entrySpeciesCode = [item.gameSpeciesCode integerValue];
    }
    else {
        DiaryEntry *item = (DiaryEntry*)entry;
        entryImages = item.diaryImages;
        entrySpeciesCode =[item.gameSpeciesCode integerValue];
    }

    if ([entryImages count] > 0) {
        // Select image that is not being deleted
        DiaryImage *shownImage = nil;
        NSArray *images = [entryImages allObjects];
        for (int i=0; i<images.count; i++) {
            DiaryImage *image = images[i];
            if ([image.status integerValue] != DiaryImageStatusDeletion) {
                shownImage = image;
                break;
            }
        }
        if (shownImage) {
            [RiistaUtils loadDiaryImage:shownImage forImageView:imageView completion:completion];
        } else {
            [RiistaUtils loadSpeciesImage:entrySpeciesCode completion:completion];
        }
    } else {
        [RiistaUtils loadSpeciesImage:entrySpeciesCode completion:completion];
    }
}

// Helper function
+ (void)loadSpeciesImage:(NSInteger)speciesCode completion:(RiistaDiaryEntryImageLoadCompletion)completion
{
    if (speciesCode == 0) {
        //SRVA other species
        UIImage *image = [[UIImage imageNamed:@"ic_question_mark_green.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        if (completion) {
            completion(image);
        }
    }
    else {
        UIImage *image = [RiistaUtils loadSpeciesImage:speciesCode];
        if (completion)
            completion(image);
    }
}

+ (void)loadDiaryImage:(DiaryImage*)image forImageView:(UIImageView*)imageView completion:(RiistaDiaryEntryImageLoadCompletion)completion
{
    if ([image.type integerValue] == DiaryImageTypeLocal) {
        [RiistaUtils loadImagefromLocalUri:image.uri fullSize:NO fixRotation:NO completion:^(UIImage* image) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIImage *resizedImage = [RiistaUtils scaleImage:image toSize:imageView.frame.size];
                if (completion)
                    completion(resizedImage);
            });
        }];
    } else if ([image.type integerValue] == DiaryImageTypeRemote) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.frame = imageView.bounds;
        [imageView addSubview:indicator];
        [indicator startAnimating];
        [[RiistaNetworkManager sharedInstance] loadDiaryEntryImage:image.imageid completion:^(UIImage *image, NSError* error) {
            if (imageView) {
                [indicator stopAnimating];
                [indicator removeFromSuperview];
                if (!error) {
                    if (completion)
                        completion(image);
                } else {
                    if (completion)
                        completion(nil);
                }
            }
        }];
    }
}

+ (void)loadDiaryImage:(DiaryImage*)image size:(CGSize)size completion:(RiistaDiaryEntryImageLoadCompletion)completion
{
    if ([image.type integerValue] == DiaryImageTypeLocal) {
        [RiistaUtils loadImagefromLocalUri:image.uri fullSize:NO fixRotation:NO completion:^(UIImage* image) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIImage *resizedImage = [RiistaUtils scaleImage:image toSize:size];
                completion(resizedImage);
            });
        }];
    } else if ([image.type integerValue] == DiaryImageTypeRemote) {
        [[RiistaNetworkManager sharedInstance] loadDiaryEntryImage:image.imageid completion:^(UIImage *image, NSError* error) {
            completion(image);
        }];
    }
}

+ (void)loadImagefromLocalUri:(NSString*)uri fullSize:(BOOL)fullsize fixRotation:(BOOL)fixRotation completion:(RiistaDiaryEntryImageLoadCompletion)completion
{
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        CGImageRef iref;
        if (fullsize) {
            iref = [rep fullResolutionImage];
        } else {
            iref = [rep fullScreenImage];
        }
        if (iref) {
            UIImageOrientation orientation = UIImageOrientationUp;
            NSNumber* orientationValue = [myasset valueForProperty:@"ALAssetPropertyOrientation"];
            if (orientationValue != nil) {
                orientation = [orientationValue intValue];
            }

            if (completion) {
                if (fixRotation) {
                    UIImage *fixedImage = [RiistaUtils fixImageOrientation:[UIImage imageWithCGImage:iref scale:1 orientation:orientation] limitMaxSize:NO];
                    completion(fixedImage);
                } else {
                    completion([UIImage imageWithCGImage:iref]);
                }
            }
        }
    };
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
        completion(nil);
    };

    if(uri && [uri length]) {
        NSURL *asseturl = [NSURL URLWithString:uri];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ALAssetsLibrary* assetslibrary = [ALAssetsLibrary new];
                [assetslibrary assetForURL:asseturl
                               resultBlock:resultblock
                              failureBlock:failureblock];
        });
    }
}

+ (UIImage*)scaleImage:(UIImage*)image toSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

+ (UIImage*)loadSpeciesImage:(NSInteger)gameSpeciesCode
{
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"species_%ld.jpg", (long)gameSpeciesCode]];
    if (!image) {
        image = [UIImage imageNamed:@"ic_launcher.png"];
    }
    return image;
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
    if (image.size.width > MAX_IMAGE_DIMEN || image.size.height > MAX_IMAGE_DIMEN) {
        return [image resizedImageToFitInSize:CGSizeMake(MAX_IMAGE_DIMEN, MAX_IMAGE_DIMEN) scaleIfSmaller:NO];
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
    return (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                (CFStringRef)originalString,
                                                                                NULL,
                                                                                CFSTR(":/?#[]@!$&'()*+,;="),
                                                                                kCFStringEncodingUTF8));
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

@end
