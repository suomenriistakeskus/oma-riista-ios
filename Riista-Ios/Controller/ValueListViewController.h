#import <UIKit/UIKit.h>

@protocol ValueSelectionDelegate

- (void)valueSelectedForKey:(NSString*)key value:(NSString*)value;

@end

@interface ValueListViewController : UITableViewController

@property (weak, nonatomic) id<ValueSelectionDelegate> delegate;
@property (strong, nonatomic) NSString *fieldKey;
@property (strong, nonatomic) NSString *titlePrompt;

@property (strong, nonatomic) NSArray *values;

// Replace key with override key when getting localized texts
- (void)setTextKeyOverride:(NSString *)key overrideKey:(NSString*)overrideKey;

@end
