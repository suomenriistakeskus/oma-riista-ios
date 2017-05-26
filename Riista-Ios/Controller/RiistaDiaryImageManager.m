#import <AssetsLibrary/AssetsLibrary.h>
#import <UIImage+Resize.h>
#import "RiistaDiaryImageManager.h"
#import "DiaryEntryBase.h"
#import "DiaryImage.h"
#import "RiistaUtils.h"
#import "RiistaAppDelegate.h"
#import "MWPhotoBrowser.h"
#import "MWCustomPhoto.h"
#import "RiistaGameDatabase.h"
#import "RiistaNetworkManager.h"
#import "RiistaLocalization.h"

@interface LocalImage : NSObject

@property (assign, nonatomic) BOOL isUserImage;
@property (strong, nonatomic) DiaryImage *image;
@property (strong, nonatomic) UIImageView *imageView;

@end

@protocol CustomPhotoBrowserDelegate <NSObject>

- (void)didEndBrowsing:(MWPhotoBrowser*)browser;

@end

@interface CustomPhotoBrowser : MWPhotoBrowser

@property (weak, nonatomic) id<CustomPhotoBrowserDelegate> statusDelegate;

@end

@interface RiistaDiaryImageManager () <UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MWPhotoBrowserDelegate, CustomPhotoBrowserDelegate>

@property (weak, nonatomic) UIViewController *parentController;
@property (weak, nonatomic) UIView *diaryImageView;
@property (weak, nonatomic) NSLayoutConstraint *contentViewHeightConstraint;
@property (weak, nonatomic) NSLayoutConstraint *layoutConstraint;
@property (strong, nonatomic) NSMutableArray *images;
@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) CustomPhotoBrowser *photoBrowser;
@property (strong, nonatomic) UIAlertView *imageSelectionAlertView;

@property (assign, nonatomic) NSInteger selectedImage;

@property (strong, nonatomic) NSManagedObjectContext *editContext;

@end

NSInteger const IMAGE_SELECTION = 100;
NSInteger const MAX_IMAGE_DIMEN = 1024;

NSInteger const IMAGE_SIZE = 50;
NSInteger const MAX_IMAGES = 1;

typedef void(^RiistaImageUrlCompletionBlock)(NSURL *imageUri);
typedef void(^PhotoInitCompletion)(NSInteger startIndex);

@implementation RiistaDiaryImageManager

- (id)initWithParentController:(UIViewController*)parentController andView:(UIView*)view andContentViewHeightConstraint:(NSLayoutConstraint*)contentViewConstraint andImageViewHeightConstraint:(NSLayoutConstraint*)constraint
       andManagedObjectContext:(NSManagedObjectContext*)editContext
{
    self = [super init];
    if (self) {
        _editMode = NO;
        _parentController = parentController;
        _diaryImageView = view;
        _contentViewHeightConstraint = contentViewConstraint;
        _layoutConstraint = constraint;
        _editContext = editContext;
        _images = [NSMutableArray new];
        if (self.images.count < MAX_IMAGES) {
            [self addImage:YES];
        }
    }
    return self;
}

- (void)dealloc
{
    if (self.imageSelectionAlertView) {
        self.imageSelectionAlertView.delegate = nil;
        [self.imageSelectionAlertView dismissWithClickedButtonIndex:self.imageSelectionAlertView.cancelButtonIndex animated:YES];
    }
}

- (void)setupWithImages:(NSArray*)images
{
    [self.images removeAllObjects];
    [self createLocalImages:images];
    if (self.images.count < MAX_IMAGES) {
        [self addImage:YES];
    }
}

- (LocalImage*)addImage:(BOOL)camera
{
    UIImageView *imageView = [UIImageView new];
    if (camera) {
        imageView.image = [UIImage imageNamed:@"ic_camera.png"];
        if (!self.editMode)
            imageView.hidden = YES;
    }
    imageView.frame = CGRectMake(0, self.images.count * IMAGE_SIZE, IMAGE_SIZE, IMAGE_SIZE);
    [imageView setUserInteractionEnabled:YES];
    imageView.tag = self.images.count;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageClick:)]];
    [self.diaryImageView addSubview:imageView];
    LocalImage *image = [LocalImage new];
    image.isUserImage = !camera;
    image.imageView = imageView;
    [self.images addObject:image];
    if (self.images.count * IMAGE_SIZE > self.layoutConstraint.constant) {
        self.contentViewHeightConstraint.constant += (self.images.count * IMAGE_SIZE - self.layoutConstraint.constant);
        self.layoutConstraint.constant = self.images.count * IMAGE_SIZE;
    }
    return image;
}

- (void)imageClick:(id)sender
{
    if (self.editMode) {
        [self editImage:sender];
    } else {
        NSInteger imageIndex = [[sender view] tag];
        LocalImage *image = self.images[imageIndex];
        if (image.isUserImage) {
            __weak RiistaDiaryImageManager *weakSelf = self;
            [self initPhotoBrowserImages:imageIndex completion:^(NSInteger startIndex) {
                [weakSelf startPhotoBrowser:startIndex];
            }];
        }
    }
}

- (void)initPhotoBrowserImages:(NSInteger)startIndex completion:(PhotoInitCompletion)completion
{
    DiaryImage *image = ((LocalImage*)self.images[startIndex]).image;
    [[RiistaGameDatabase sharedInstance] userImagesWithCurrentImage:image entryType:self.entryType completion:^(NSArray *images, NSUInteger currentIndex) {
        self.photos = images;
        if (completion)
            completion(currentIndex);
    }];
}

- (void)startPhotoBrowser:(NSInteger)startIndex
{
    self.photoBrowser = [[CustomPhotoBrowser alloc] initWithDelegate:self];
    self.photoBrowser.statusDelegate = self;
    self.photoBrowser.displayActionButton = NO;
    self.photoBrowser.displayNavArrows = NO;
    self.photoBrowser.displaySelectionButtons = NO;
    self.photoBrowser.zoomPhotosToFill = YES;
    self.photoBrowser.alwaysShowControls = YES;
    self.photoBrowser.enableGrid = NO;
    self.photoBrowser.startOnGrid = NO;
    [self.photoBrowser setCurrentPhotoIndex:startIndex];
    [self.parentController.navigationController pushViewController:self.photoBrowser animated:YES];
    [self.delegate imageBrowserOpenStatusChanged:YES];
}

- (void)editImage:(id)sender
{
    RiistaLanguageRefresh;
    self.selectedImage = [[sender view] tag];

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imageSelectionAlertView = [[UIAlertView alloc]
                              initWithTitle:RiistaLocalizedString(@"ChooseImageSource", nil)
                              message:nil
                              delegate:self
                              cancelButtonTitle:nil
                              otherButtonTitles:nil];
        NSArray* sourceTypes = @[RiistaLocalizedString(@"CameraSource", nil), RiistaLocalizedString(@"GallerySource", nil)];
        for (int i=0; i<sourceTypes.count; i++) {
            [self.imageSelectionAlertView addButtonWithTitle:sourceTypes[i]];
        }
        [self.imageSelectionAlertView addButtonWithTitle:RiistaLocalizedString(@"CancelRemove", nil)];
        self.imageSelectionAlertView.cancelButtonIndex = sourceTypes.count;
        self.imageSelectionAlertView.tag = IMAGE_SELECTION;
        [self.imageSelectionAlertView show];
    } else {
        [self addImageWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }

}

- (void)setEditMode:(BOOL)editMode
{
    _editMode = editMode;
    for (LocalImage *image in self.images) {
        if (!image.isUserImage)
            image.imageView.hidden = !editMode;
    }
}

# pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && buttonIndex == 0) {
        [self addImageWithSourceType:UIImagePickerControllerSourceTypeCamera];
    } else {
        [self addImageWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

- (void)addImageWithSourceType:(UIImagePickerControllerSourceType)type
{
    UIImagePickerController *imagePicker = [UIImagePickerController new];
    imagePicker.delegate = self;
    imagePicker.sourceType = type;
    [self.parentController presentViewController:imagePicker animated:YES completion:nil];
}

- (void)createLocalImages:(NSArray*)diaryImages
{
    int imagesAdded = 0;
    for (int i=0; i<diaryImages.count && imagesAdded<MAX_IMAGES; i++) {
        DiaryImage *image = diaryImages[i];
        // Deleted images are ignored. Those images will be marked again for deletion
        if ([image.status integerValue] != DiaryImageStatusDeletion) {
            LocalImage* localImage = [self addImage:NO];
            localImage.image = image;
            [RiistaUtils loadDiaryImage:diaryImages[i] forImageView:localImage.imageView completion:^(UIImage* image) {
                if (localImage)
                    localImage.imageView.image = image;
            }];
            imagesAdded++;
        }
    }
}

- (BOOL)hasImages
{
    return [self.images count] > 0;
}

- (NSArray*)diaryImages
{
    NSMutableArray *diaryImages = [NSMutableArray new];
    for (int i=0; i<self.images.count; i++) {
        LocalImage *localImage = self.images[i];
        if (localImage.isUserImage) {
            [diaryImages addObject:localImage.image];
        }
    }
    return [diaryImages copy];
}

- (void)restartImageBrowser
{
    if (self.photoBrowser)
        [self startPhotoBrowser:self.photoBrowser.currentIndex];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    LocalImage *localImage = (LocalImage*)self.images[self.selectedImage];
    UIImage *image = [RiistaUtils scaleImage:info[UIImagePickerControllerOriginalImage] toSize:localImage.imageView.frame.size];
    localImage.imageView.image = image;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DiaryImage" inManagedObjectContext:self.editContext];
    localImage.image = (DiaryImage*)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.editContext];
    
    // Give unique UUID identifier
    localImage.image.imageid = [[NSUUID UUID] UUIDString];

    localImage.image.type = [NSNumber numberWithInteger:DiaryImageTypeLocal];
    if (self.images.count < MAX_IMAGES && !localImage.isUserImage) {
        [self addImage:YES];
    }
    localImage.isUserImage = YES;
    [self imageUri:info completion:^(NSURL *imageUri) {
        localImage.image.uri = [imageUri absoluteString];
        [self.parentController dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)imageUri:(NSDictionary*)info completion:(RiistaImageUrlCompletionBlock)completion
{
    NSURL *url = [(NSURL*)info valueForKey:UIImagePickerControllerReferenceURL];
    if (url) {
        completion(url);
    } else {
        UIImage *originalImage = (UIImage*)info[UIImagePickerControllerOriginalImage];
        UIImage *scaledImage = [RiistaUtils imageAsDownscaledImage:originalImage];
        NSData* scaledData = UIImageJPEGRepresentation(scaledImage, 1.0);

        //Update orientation metadata if the image was actually scaled down
        NSMutableDictionary *metadata = [info[UIImagePickerControllerMediaMetadata] mutableCopy];
        metadata[@"Orientation"] = @(scaledImage.imageOrientation);

        ALAssetsLibrary *library = [ALAssetsLibrary new];
        [library writeImageDataToSavedPhotosAlbum:scaledData metadata:metadata completionBlock:^(NSURL *assetUrl, NSError *error) {
            completion(assetUrl);
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    [self.parentController dismissViewControllerAnimated:YES completion:nil];
}
                                   
#pragma mark - MWPhotoDelegate
                                   
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser*)photoBrowser
{
    return self.photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser*)photoBrowser photoAtIndex:(NSUInteger)index
{
    DiaryImage *image = self.photos[index];
    return [MWCustomPhoto photoWithDiaryImage:image];
}

- (void)photoBrowser:(MWPhotoBrowser*)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index;
{
    if (self.delegate) {
        DiaryImage *image = self.photos[index];
        if ([self.entryType isEqualToString:DiaryEntryTypeObservation]) {
            [self.delegate RiistaDiaryImageManager:self selectedEntry:(DiaryEntryBase*)image.observationEntry];
        }
        else if ([self.entryType isEqualToString:DiaryEntryTypeSrva]) {
            [self.delegate RiistaDiaryImageManager:self selectedEntry:(DiaryEntryBase*)image.srvaEntry];
        }
        else {
            [self.delegate RiistaDiaryImageManager:self selectedEntry:(DiaryEntryBase*)image.diaryEntry];
        }
    }
}

#pragma mark - CustomPhotoBrowserDelegate

- (void)didEndBrowsing:(MWPhotoBrowser*)browser
{
    if (self.delegate) {
        [self.delegate imageBrowserOpenStatusChanged:NO];
    }
}

@end

@implementation LocalImage
@end

@implementation CustomPhotoBrowser

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.statusDelegate) {
        [self.statusDelegate didEndBrowsing:self];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end
