#import "UILabel+CustomFont.h"

@implementation UILabel (FontOverride)

- (void)setSubstituteFontName:(NSString *)name UI_APPEARANCE_SELECTOR {
    if ([self.font.familyName isEqualToString:name]) {
        // Same font family and the font is possibly already configured (point size, bold, italic etc).
        // --> don't reload font as we would probably lose configuration
        return;
    }

    UIFontDescriptor *fontDescriptor = [self.font.fontDescriptor fontDescriptorWithFamily:name];
    self.font = [UIFont fontWithDescriptor:fontDescriptor size:0.0]; // 0.0 --> respect font descriptor values
}
@end
