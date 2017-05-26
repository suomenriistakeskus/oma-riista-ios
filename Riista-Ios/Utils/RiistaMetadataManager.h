#import "MetadataManager.h"
#import "RiistaNetworkManager.h"

@class SrvaMetadata;

@interface RiistaMetadataManager : NSObject <MetadataManager>

+ (RiistaMetadataManager*)sharedInstance;

- (BOOL)hasSrvaMetadata;
- (SrvaMetadata*)getSrvaMetadata;

- (void)fetchObservationMetadata:(RiistaDiaryObservationMetaCompletion)completion;
- (void)fetchSrvaMetadata:(RiistaDiarySrvaMetaCompletion)completion;
- (void)fetchAll;

@end
