#import "RiistaSpecimenView.h"
#import "RiistaSpecimen.h"
#import "RiistaLocalization.h"
#import "KeyboardToolbarView.h"

#import "Oma_riista-Swift.h"

@implementation RiistaSpecimenView
{
    BOOL isGenderRequired;
    BOOL isAgeRequired;
    BOOL isWeightRequired;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    _weightInput.delegate = self;
    _weightInput.keyboardType = UIKeyboardTypeDecimalPad;
    _weightInput.inputAccessoryView = [KeyboardToolbarView textFieldDoneToolbarView:_weightInput];

    _weightInputController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:_weightInput];
    [_weightInputController applyThemeWithScheme:AppTheme.shared.textFieldContainerScheme];

    [AppTheme.shared setupSegmentedControllerWithSegmentedController:_genderSelect];
    [AppTheme.shared setupSegmentedControllerWithSegmentedController:_ageSelect];

    [_genderSelect addTarget:self action:@selector(genderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_ageSelect addTarget:self action:@selector(ageValueChanged:) forControlEvents:UIControlEventValueChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(weightValueChanged:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:_weightInput];
}

- (void)updateLocalizedTexts
{
    [_genderSelect setImage:[UIImage textEmbededImageWithImage:[UIImage imageNamed:@"female"]
                                                        string:RiistaLocalizedString(@"SpecimenGenderFemale", nil)
                                                         color:UIColor.blackColor
                                                imageAlignment:0
                                                       segFont:[UIFont fontWithName:AppFont.Name size:AppFont.LabelMedium]]
          forSegmentAtIndex:0];
    [_genderSelect setImage:[UIImage textEmbededImageWithImage:[UIImage imageNamed:@"male"]
                                                        string:RiistaLocalizedString(@"SpecimenGenderMale", nil)
                                                         color:[UIColor applicationColor:Primary]
                                                imageAlignment:0
                                                       segFont:[UIFont fontWithName:AppFont.Name size:AppFont.LabelMedium]]
          forSegmentAtIndex:1];

    [_ageSelect setTitle:RiistaLocalizedString(@"SpecimenAgeAdult", nil) forSegmentAtIndex:0];
    [_ageSelect setTitle:RiistaLocalizedString(@"SpecimenAgeYoung", nil) forSegmentAtIndex:1];

    [_weightInputController setPlaceholderText:RiistaLocalizedString(@"SpecimenWeightTitle", nil)];
}

- (void)updateValueSelections
{
    // Selected gender
    if ([_specimen.gender isEqualToString:SpecimenGenderFemale]) {
        [_genderSelect setSelectedSegmentIndex:0];
    }
    else if ([_specimen.gender isEqualToString:SpecimenGenderMale]) {
        [_genderSelect setSelectedSegmentIndex:1];
    }
    else {
        [_genderSelect setSelectedSegmentIndex:-1];
    }

    // Selected age
    if ([_specimen.age isEqualToString:SpecimenAgeAdult]) {
        [_ageSelect setSelectedSegmentIndex:0];
    }
    else if ([_specimen.age isEqualToString:SpecimenAgeYoung]) {
        [_ageSelect setSelectedSegmentIndex:1];
    }
    else {
        [_ageSelect setSelectedSegmentIndex:-1];
    }

    _weightInput.text = _specimen.weight == nil ? nil
        : [NSNumberFormatter localizedStringFromNumber:_specimen.weight numberStyle:NSNumberFormatterDecimalStyle];
}

- (void)setRequiresGender:(BOOL)genderRequired andAge:(BOOL)ageRequired andWeight:(BOOL)weightRequired
{
    isGenderRequired = genderRequired;
    isAgeRequired = ageRequired;
    isWeightRequired = weightRequired;

    [self refreshRequiredValueIndicators];
}

- (void)refreshRequiredValueIndicators
{
    [self.genderRequiredIndicator setHidden:!(isGenderRequired && [[self.specimen gender] length] == 0)];
    [self.ageRequiredIndicator setHidden:!(isAgeRequired && [[self.specimen age] length] == 0)];
    [self.weightRequiredIndicator setHidden:!(isWeightRequired && [self.specimen weight] == 0)];
}

- (void)genderValueChanged:(UISegmentedControl*)sender
{
    if (sender.selectedSegmentIndex == 0) {
        _specimen.gender = SpecimenGenderFemale;
    }
    else if (sender.selectedSegmentIndex == 1) {
        _specimen.gender = SpecimenGenderMale;
    }
    else {
        _specimen.gender = nil;
    }

    [self refreshRequiredValueIndicators];

    if (_genderAndAgeListener) {
        _genderAndAgeListener();
    }
}

- (void)ageValueChanged:(UISegmentedControl*)sender
{
    if (sender.selectedSegmentIndex == 0) {
        _specimen.age = SpecimenAgeAdult;
    }
    else if (sender.selectedSegmentIndex == 1) {
        _specimen.age = SpecimenAgeYoung;
    }
    else {
        _specimen.age = nil;
    }

    [self refreshRequiredValueIndicators];

    if (_genderAndAgeListener) {
        _genderAndAgeListener();
    }
}

- (void)weightValueChanged:(id)sender
{
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    _specimen.weight = [formatter numberFromString:[_weightInput text]];

    [self refreshRequiredValueIndicators];

    if (_genderAndAgeListener) {
        _genderAndAgeListener();
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.weightInput)
    {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];

        NSString *pattern = @"^([0-9]{0,3}(([\\.,][0-9])||([\\.,])))?$";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:newString
                                                            options:0
                                                              range:NSMakeRange(0, [newString length])];
        if (numberOfMatches == 0)
            return NO;
    }

    return YES;
}

- (void)hideWeightInput:(BOOL)hide
{
    [self.hideWeightInputContainerConstraint setConstrainedViewHiddenWithHidden:hide];
    [self.weightInputContainer setHidden:hide];
    // Only override visibility here when hiding all weight views
    if (hide) {
        [self.weightRequiredIndicator setHidden:hide];
    }
    [self.weightInputContainer layoutIfNeeded];
}

@end
