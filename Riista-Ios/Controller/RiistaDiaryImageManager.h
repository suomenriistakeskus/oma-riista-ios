#import <Foundation/Foundation.h>
#import "DiaryEntryBase.h"

@class RiistaDiaryImageManager;

extern NSInteger const IMAGE_SELECTION;
extern NSInteger const MAX_IMAGE_DIMEN;

@protocol RiistaDiaryImageManagerDelegate

- (void)imageBrowserOpenStatusChanged:(BOOL)open;
- (void)RiistaDiaryImageManager:(RiistaDiaryImageManager*)manager selectedEntry:(DiaryEntryBase*)entry;

@end

@interface RiistaDiaryImageManager : NSObject

@property (weak, nonatomic) id<RiistaDiaryImageManagerDelegate> delegate;
@property (assign, nonatomic) BOOL editMode;
@property (strong, nonatomic) NSString *entryType;

- (id)initWithParentController:(UIViewController*)parentController andView:(UIView*)view andContentViewHeightConstraint:(NSLayoutConstraint*)contentViewConstraint andImageViewHeightConstraint:(NSLayoutConstraint*)constraint
       andManagedObjectContext:(NSManagedObjectContext*)context;

- (void)setupWithImages:(NSArray*)images;

- (BOOL)hasImages;

- (NSArray*)diaryImages;

- (void)restartImageBrowser;

@end
