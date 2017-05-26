#import "DiaryImage.h"

NSInteger const DiaryImageTypeLocal = 0;
NSInteger const DiaryImageTypeRemote = 1;

NSInteger const DiaryImageStatusInsertion = 1;
NSInteger const DiaryImageStatusDeletion = 2;

@implementation DiaryImage

@dynamic type;
@dynamic imageid;
@dynamic uri;
@dynamic status;
@dynamic diaryEntry;
@dynamic observationEntry;
@dynamic srvaEntry;

@end
