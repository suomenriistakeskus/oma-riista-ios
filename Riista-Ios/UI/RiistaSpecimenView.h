#import <UIKit/UIKit.h>
#import "Oma_riista-Swift.h"

typedef void (^SpecimenGenderAndAgeListener)(void);

@class RiistaSpecimen;

@interface RiistaSpecimenView : UIStackView <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSelect;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ageSelect;
@property (weak, nonatomic) IBOutlet MDCTextField *weightInput;
@property (weak, nonatomic) IBOutlet UIView *weightInputContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hideWeightInputContainerConstraint;

@property (weak, nonatomic) IBOutlet UILabel *genderRequiredIndicator;
@property (weak, nonatomic) IBOutlet UILabel *ageRequiredIndicator;
@property (weak, nonatomic) IBOutlet UILabel *weightRequiredIndicator;

@property (nonatomic, copy) SpecimenGenderAndAgeListener genderAndAgeListener;

@property (strong, nonatomic) MDCTextInputControllerUnderline *weightInputController;

@property (strong, nonatomic) RiistaSpecimen *specimen;

- (void)updateLocalizedTexts;
- (void)updateValueSelections;
- (void)setRequiresGender:(BOOL)genderRequired andAge:(BOOL)ageRequired andWeight:(BOOL)weightRequired;
- (void)hideWeightInput:(BOOL)hide;

@end
