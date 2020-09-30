#ifndef UILabel_CustomFont_h
#define UILabel_CustomFont_h

@interface UILabel (FontOverride)
- (void)setSubstituteFontName:(NSString *)name UI_APPEARANCE_SELECTOR;
@end

#endif /* UILabel_CustomFont_h */
