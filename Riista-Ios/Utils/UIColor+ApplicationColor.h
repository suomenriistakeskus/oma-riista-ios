#import <Foundation/Foundation.h>

typedef enum {
    RiistaApplicationColorButtonBackground,
    RiistaApplicationColorButtonBackgroundHighlighted,
    RiistaApplicationColorButtonBackgroundDisabled,
    RiistaApplicationColorNegativeButtonBackground,
    RiistaApplicationColorNegativeButtonBackgroundHighlighted,
    RiistaApplicationColorWhiteButtonHilight,
    RiistaApplicationColorTextFieldBackground,
    RiistaApplicationColorNavigationBackground,
    RiistaMenuSelectColour,
    RiistaSeparatorColour,
    RiistaApplicationColorBackground,
    RiistaApplicationColorDiaryCellBorder,
    RiistaApplicationColorTextDisabled,
    RiistaApplicationColorLink,
    RiistaApplicationColorLinkHighlighted,
    RiistaApplicationColorHarvestPermitStatusProposed,
    RiistaApplicationColorHarvestPermitStatusAccepted,
    RiistaApplicationColorHarvestPermitStatusRejected,
    RiistaApplicationColorHarvestStatusCreateReport,
    RiistaApplicationColorHarvestStatusProposed,
    RiistaApplicationColorHarvestStatusSentForApproval,
    RiistaApplicationColorHarvestStatusApproved,
    RiistaApplicationColorHarvestStatusRejected
} RiistaApplicationColor;

@interface UIColor (ApplicationColor)

/**
 * @param Predefined application color type
 * @returns Color type corresponding color object
 */
+ (UIColor*)applicationColor:(RiistaApplicationColor)applicationColor;

@end
