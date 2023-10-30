#import "UIColor+ApplicationColor.h"

@implementation UIColor (ApplicationColor)

+ (UIColor*)applicationColor:(RiistaApplicationColor)applicationColor
{
    static NSDictionary *colorDictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorDictionary = @{ @(RiistaApplicationColorButtonBackground): [UIColor colorWithHexValue:0x136925],
            @(RiistaApplicationColorButtonBackgroundHighlighted): [UIColor colorWithHexValue:0x238935],
            @(RiistaApplicationColorButtonBackgroundDisabled): [UIColor colorWithHexValue:0xA3C9A5],
            @(RiistaApplicationColorNegativeButtonBackground): [UIColor colorWithHexValue:0x676767],
            @(RiistaApplicationColorNegativeButtonBackgroundHighlighted): [UIColor colorWithHexValue:0x878787],
            @(RiistaApplicationColorWhiteButtonHilight): [UIColor colorWithHexValue:0xEFEFEF],
            @(RiistaApplicationColorTextFieldBackground): [UIColor colorWithHexValue:0xE8E8E8],
            @(RiistaApplicationColorNavigationBackground): [UIColor colorWithHexValue:0x2F882E],
            @(RiistaMenuSelectColour): [UIColor colorWithHexValue:0xE7F7ED],
            @(RiistaSeparatorColour): [UIColor colorWithHexValue:0xDDDDDD],
            @(RiistaApplicationColorBackground): [UIColor colorWithHexValue:0xF0F0F0],
            @(RiistaApplicationColorDiaryCellBorder): [UIColor colorWithHexValue:0xDFDFDF],
            @(RiistaApplicationColorTextDisabled): [UIColor colorWithHexValue:0x888888],
            @(RiistaApplicationColorLink): [UIColor colorWithHexValue:0x2F882E],
            @(RiistaApplicationColorLinkHighlighted): [UIColor colorWithHexValue:0x3F983E],

            @(RiistaApplicationColorHarvestPermitStatusProposed): [UIColor colorWithHexValue:0xd2ad00],
            @(RiistaApplicationColorHarvestPermitStatusAccepted): [UIColor colorWithHexValue:0x004923],
            @(RiistaApplicationColorHarvestPermitStatusRejected): [UIColor colorWithHexValue:0xc44d4a],

            @(RiistaApplicationColorHarvestStatusCreateReport): [UIColor colorWithHexValue:0xc44d4a],
            @(RiistaApplicationColorHarvestStatusProposed): [UIColor colorWithHexValue:0xd2ad00],
            @(RiistaApplicationColorHarvestStatusSentForApproval): [UIColor colorWithHexValue:0xd2ad00],
            @(RiistaApplicationColorHarvestStatusApproved): [UIColor colorWithHexValue:0x004923],
            @(RiistaApplicationColorHarvestStatusRejected): [UIColor colorWithHexValue:0xc44d4a],

            @(ShootingTestQualifiedColor): [UIColor colorWithHexValue:0x2F882E],
            @(ShootingTestUnqualifiedColor): [UIColor colorWithHexValue:0xC72525],
            @(ShootingTestIntendedColor): [UIColor colorWithHexValue:0x56BACD],
            @(ShootingTestNotIntendedColor): [UIColor colorWithHexValue:0x56BACD],

    // Updated facelift colors after this

             @(Primary): [UIColor colorWithHexValue:0x2F882E],
             @(PrimaryDark): [UIColor colorWithHexValue:0x185617],
             @(PrimaryVariant): [UIColor colorWithHexValue:0x354935],
             @(TextPrimary): [UIColor colorWithHexValue:0x202020],
             @(TextSecondary): [UIColor colorWithHexValue:0x202020],
             @(TextOnPrimary): [UIColor colorWithHexValue:0xFFFFFF],
             @(ViewBackground): [UIColor colorWithHexValue:0xFFFFFF],
             @(GreyDark): [UIColor colorWithHexValue:0x6A6A6A],
             @(GreyMedium): [UIColor colorWithHexValue:0x9E9E9E],
             @(GreyLight): [UIColor colorWithHexValue:0xD9D9D9],
             @(Destructive): [UIColor colorWithHexValue:0xC72525],
             @(ApplicationGreen): [UIColor colorWithHexValue:0x2F882E],
             @(ApplicationYellow): [UIColor colorWithHexValue:0xFFCC00],
             @(ApplicationRed): [UIColor colorWithHexValue:0xC72525],
            };
    });

    return [colorDictionary objectForKey:@(applicationColor)];
}

+ (UIColor*)colorWithHexValue:(int32_t)hexValue
{
    return [UIColor colorWithRed:((float)((hexValue & 0xff0000) >> 16))/255.0
                           green:((float)((hexValue & 0xff00) >> 8))/255.0
                            blue:((float)(hexValue & 0xff))/255.0 alpha:1.0 ];
}

@end
