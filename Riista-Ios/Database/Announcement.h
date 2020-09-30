#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AnnouncementSender;

NS_ASSUME_NONNULL_BEGIN

@interface Announcement : NSManagedObject

- (NSString *)senderAsText;
- (NSString *)timeAsText;

@end

NS_ASSUME_NONNULL_END

#import "Announcement+CoreDataProperties.h"
