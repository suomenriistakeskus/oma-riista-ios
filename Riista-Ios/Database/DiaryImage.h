#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern const NSInteger DiaryImageTypeLocal;
extern const NSInteger DiaryImageTypeRemote;

extern const NSInteger DiaryImageStatusInsertion;
extern const NSInteger DiaryImageStatusDeletion;

@class DiaryEntry;
@class ObservationEntry;
@class SrvaEntry;

@interface DiaryImage : NSManagedObject

@property (nonatomic, retain) NSNumber *type;
@property (nonatomic, retain) NSString *imageid;
@property (nonatomic, retain) NSString *uri;
@property (nonatomic, retain) NSString *localIdentifier;
@property (nonatomic, retain) NSNumber *status;
@property (nonatomic, retain) DiaryEntry *diaryEntry;
@property (nonatomic, retain) ObservationEntry *observationEntry;
@property (nonatomic, retain) SrvaEntry *srvaEntry;

@end
