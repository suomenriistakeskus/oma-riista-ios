#import <Foundation/Foundation.h>

@interface RiistaSpecies : NSObject

@property (assign, nonatomic) NSInteger speciesId;
@property (strong, nonatomic) NSDictionary *name;
@property (assign, nonatomic) NSInteger categoryId;
@property (strong, nonatomic) NSURL *imageUrl;
@property (assign, nonatomic) BOOL multipleSpecimenAllowedOnHarvests;

@end
