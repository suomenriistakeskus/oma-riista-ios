#import "Announcement.h"


NS_ASSUME_NONNULL_BEGIN

@interface Announcement (CoreDataProperties)

+ (NSFetchRequest<Announcement *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *remoteId;
@property (nullable, nonatomic, copy) NSNumber *rev;
@property (nullable, nonatomic, copy) NSDate *pointOfTime;
@property (nullable, nonatomic, copy) NSString *subject;
@property (nullable, nonatomic, copy) NSString *body;
@property (nullable, nonatomic, retain) AnnouncementSender *sender;

@end

NS_ASSUME_NONNULL_END
