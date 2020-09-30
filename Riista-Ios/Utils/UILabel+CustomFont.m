#import "UILabel+CustomFont.h"

@implementation UILabel (FontOverride)

- (void)setSubstituteFontName:(NSString *)name UI_APPEARANCE_SELECTOR {
    self.font = [UIFont fontWithName:name size:self.font.pointSize];
}
@end
