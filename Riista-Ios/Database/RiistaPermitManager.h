#import <Foundation/Foundation.h>
#import "RiistaNetworkManager.h"

@class Permit;
@class PermitSpeciesAmounts;

@interface RiistaPermitManager : NSObject

+ (RiistaPermitManager*)sharedInstance;

- (NSArray*)getAllPermits;
- (NSArray*)getAvailablePermits;
- (Permit*)getPermit:(NSString*)permitNumber;
- (PermitSpeciesAmounts*)getSpeciesAmountFromPermit:(Permit*)permit forSpecies:(int)speciesCode;

- (void)clearPermits;

- (void)addManualPermit:(Permit*)permit;
- (void)preloadPermits:(RiistaPermitPreloadCompletion)completion;

- (BOOL)validateEntryWithPermit:(DiaryEntry*)entry permit:(Permit*)permit;
- (BOOL)validateEntryPermitInformation:(DiaryEntry*)entry;
- (BOOL)validateEntryPermitInformation:(NSNumber*)gameSpeciesCode
                           pointOfTime:(NSDate*)pointOfTime
                                amount:(NSNumber*)amount
                             specimens:(NSOrderedSet*)specimens
                                permit:(Permit*)permit;
- (BOOL)isSpeciesSeasonActive:(PermitSpeciesAmounts*)speciesItem daysTolerance:(int)daysTolerance;

@end
