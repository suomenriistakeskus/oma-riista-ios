#import <Foundation/Foundation.h>

@interface RiistaCredentials : NSObject

@property (strong, nonatomic) NSString* username;
@property (strong, nonatomic) NSString* password;

@end

@interface RiistaSessionManager : NSObject

+ (RiistaSessionManager*)sharedInstance;

- (void)initializeSession;

- (RiistaCredentials*)userCredentials;

- (void)storeUserLogin;

- (void)storeCredentials:(RiistaCredentials*)credentials;

- (void)removeCredentials;

@end
