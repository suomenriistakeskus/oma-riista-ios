#import "AnnouncementSender.h"


NS_ASSUME_NONNULL_BEGIN

@interface AnnouncementSender (CoreDataProperties)

+ (NSFetchRequest<AnnouncementSender *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *fullName;
@property (nullable, nonatomic, strong) NSDictionary *title;
@property (nullable, nonatomic, strong) NSDictionary *organisation;
@property (nullable, nonatomic, retain) Announcement *announcement;

@end

NS_ASSUME_NONNULL_END
