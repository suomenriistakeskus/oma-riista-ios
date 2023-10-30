#import "DiaryEntryBase.h"

NSString *const DiaryEntryTypeHarvest = @"HARVEST";
NSString *const DiaryEntryTypeObservation = @"OBSERVATION";
NSString *const DiaryEntryTypeSrva = @"SRVA";

NSInteger const DiaryEntryOperationNone = 0;
NSInteger const DiaryEntryOperationInsert = 1;
NSInteger const DiaryEntryOperationUpdate = 2;
NSInteger const DiaryEntryOperationDelete = 3;

NSInteger const DiaryEntrySpecimenDetailsMax = 25;

@implementation DiaryEntryBase

- (BOOL)isEditable
{
    [NSException raise:@"Invoked abstract method" format:@"Invoked abstract method"];
    return NO;
}

@end
