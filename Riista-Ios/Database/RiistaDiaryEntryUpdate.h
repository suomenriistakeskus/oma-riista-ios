#import <Foundation/Foundation.h>

@class DiaryEntry;
@class ObservationEntry;
@class SrvaEntry;

typedef enum {
    UpdateTypeInsert,
    UpdateTypeUpdate,
    UpdateTypeDelete
} UpdateType;

@interface RiistaDiaryEntryUpdate : NSObject

@property (strong, nonatomic) DiaryEntry *entry;
@property (strong, nonatomic) ObservationEntry *observation;
@property (strong, nonatomic) SrvaEntry *srva;
@property (assign, nonatomic) UpdateType type;

@end
