#import <Foundation/Foundation.h>

@interface RiistaClubAreaMap : NSObject<NSCoding>

@property (nonatomic, retain) NSString *type;
@property (nonatomic) NSInteger huntingYear;
@property (nonatomic, retain) NSDictionary *name;
@property (nonatomic, retain) NSDictionary *club;
@property (nonatomic, retain) NSString *externalId;
@property (nonatomic, retain) NSString *modificationTime;
@property (nonatomic) BOOL manuallyAdded;

-(id)initWithDict:(NSDictionary*)dict;

-(id)initWithCoder:(NSCoder*)decoder;
-(void)encodeWithCoder:(NSCoder*)encoder;

@end
