#import "MWCustomPhoto.h"
#import "DiaryImage.h"
#import "RiistaUtils.h"

@interface MWCustomPhoto () {
    BOOL _loadingInProgress;
}

@property (strong, nonatomic) DiaryImage *diaryImage;

@end

@implementation MWCustomPhoto

@synthesize underlyingImage = _underlyingImage; // synth property from protocol

#pragma mark - Class Methods

+ (MWCustomPhoto*)photoWithDiaryImage:(DiaryImage*)image {
	return [[MWCustomPhoto alloc] initWithDiaryImage:image];
}

#pragma mark - Init

- (id)initWithDiaryImage:(DiaryImage*)diaryImage {
	if ((self = [super init])) {
		_diaryImage = diaryImage;
	}
	return self;
}

#pragma mark - MWPhoto Protocol Methods

- (UIImage *)underlyingImage {
    return _underlyingImage;
}

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (_loadingInProgress) return;
    _loadingInProgress = YES;
    @try {
        if (self.underlyingImage) {
            [self imageLoadingComplete];
        } else {
            [self performLoadUnderlyingImageAndNotify];
        }
    }
    @catch (NSException *exception) {
        self.underlyingImage = nil;
        _loadingInProgress = NO;
        [self imageLoadingComplete];
    }
    @finally {
    }
}

// Set the underlyingImage
- (void)performLoadUnderlyingImageAndNotify {

    CGSize rect = [UIScreen mainScreen].bounds.size;
    [RiistaUtils loadDiaryImage:self.diaryImage size:rect completion:^(UIImage *image) {
        self.underlyingImage = image;
        [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
    }];
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingImage {
    _loadingInProgress = NO;
	self.underlyingImage = nil;
}

- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _loadingInProgress = NO;
    // Notify on next run loop
    [self performSelector:@selector(postCompleteNotification) withObject:nil afterDelay:0];
}

- (void)postCompleteNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                                        object:self];
}

- (void)cancelAnyLoading {
    _loadingInProgress = NO;
}

@end
