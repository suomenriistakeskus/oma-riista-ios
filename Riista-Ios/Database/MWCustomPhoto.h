#import <Foundation/Foundation.h>
#import "MWPhotoProtocol.h"

@class DiaryImage;

@interface MWCustomPhoto : NSObject <MWPhoto>

@property (nonatomic, strong) NSString *caption;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSURL *photoURL;
@property (nonatomic, readonly) NSString *filePath  __attribute__((deprecated("Use photoURL"))); // Depreciated

+ (MWCustomPhoto*)photoWithDiaryImage:(DiaryImage*)image;
- (id)initWithDiaryImage:(DiaryImage*)image;

@end
