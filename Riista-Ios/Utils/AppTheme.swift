import Foundation
import DropDown
import MaterialComponents

class AppTheme: NSObject {

    private static var singleton = AppTheme()

    @objc static var shared: AppTheme {
        return singleton
    }

    private override init() {
        super.init()

        configureDropDown()
    }

    func createTypographyCheme(buttonTextSize: CGFloat = AppConstants.Font.ButtonMedium, bolded: Bool = false) -> MDCTypographyScheme {
        let scheme = MDCTypographyScheme()

        scheme.headline1 = fontForSize(size: AppConstants.Font.Headline, bolded: bolded)
        scheme.headline2 = fontForSize(size: AppConstants.Font.Headline, bolded: bolded)
        scheme.headline3 = fontForSize(size: AppConstants.Font.Headline, bolded: bolded)
        scheme.headline4 = fontForSize(size: AppConstants.Font.Headline, bolded: bolded)
        scheme.headline5 = fontForSize(size: AppConstants.Font.Headline, bolded: bolded)
        scheme.headline6 = fontForSize(size: AppConstants.Font.Headline, bolded: bolded)
        scheme.subtitle1 = fontForSize(size: AppConstants.Font.Headline, bolded: bolded)
        scheme.subtitle2 = fontForSize(size: AppConstants.Font.Headline, bolded: bolded)
        scheme.body1 = fontForSize(size: AppConstants.Font.LabelMedium, bolded: bolded)
        scheme.body2 = fontForSize(size: AppConstants.Font.LabelMedium, bolded: bolded)
        scheme.caption = fontForSize(size: AppConstants.Font.LabelMedium, bolded: bolded)
        scheme.button = fontForSize(size: buttonTextSize, bolded: bolded)
        scheme.overline = fontForSize(size: AppConstants.Font.LabelMedium, bolded: bolded)

        return scheme
    }

    func fontForSize(size: CGFloat, bolded: Bool = false) -> UIFont {
        let fontWeight: UIFont.Weight
        if (bolded) {
            fontWeight = .bold
        } else {
            fontWeight = .regular
        }

        return UIFont.appFont(fontSize: size, fontWeight: fontWeight)
    }

    @objc func buttonContainerScheme() -> MDCContainerScheme {
        let containerScheme = MDCContainerScheme()

        containerScheme.colorScheme = colorScheme()
        containerScheme.typographyScheme = createTypographyCheme()

        return containerScheme
    }

    @objc func cardButtonScheme() -> MDCContainerScheme {
        let containerScheme = MDCContainerScheme()

        containerScheme.colorScheme = colorScheme()
        containerScheme.typographyScheme = createTypographyCheme()

        return containerScheme
    }

    @objc func cardButtonSchemeBolded() -> MDCContainerScheme {
        let containerScheme = MDCContainerScheme()

        containerScheme.colorScheme = colorScheme()
        containerScheme.typographyScheme = createTypographyCheme(buttonTextSize: AppConstants.Font.ButtonMedium, bolded: true)

        return containerScheme
    }

    func outlineButtonSchemeSmall() -> MDCContainerScheme {
        let containerScheme = MDCContainerScheme()

        containerScheme.colorScheme = colorScheme()
        containerScheme.typographyScheme = createTypographyCheme(buttonTextSize: AppConstants.Font.ButtonSmall)

        return containerScheme
    }

    @objc func outlineButtonScheme() -> MDCContainerScheme {
        let containerScheme = MDCContainerScheme()

        containerScheme.colorScheme = colorScheme()
        containerScheme.typographyScheme = createTypographyCheme()

        return containerScheme
    }

    @objc func imageButtonScheme() -> MDCContainerScheme {
        let containerScheme = MDCContainerScheme()

        containerScheme.colorScheme = colorScheme()
        containerScheme.typographyScheme = createTypographyCheme()

        return containerScheme
    }

    @objc func primaryButtonScheme() -> MDCContainerScheme {
        let containerScheme = MDCContainerScheme()

        containerScheme.colorScheme = colorScheme()
        containerScheme.typographyScheme = createTypographyCheme()

        return containerScheme
    }

    @objc func secondaryButtonScheme() -> MDCContainerScheme {
        let containerScheme = MDCContainerScheme()

        containerScheme.colorScheme = colorScheme()
        containerScheme.typographyScheme = createTypographyCheme()

        return containerScheme
    }

    @objc func textButtonScheme() -> MDCContainerScheme {
        let containerScheme = MDCContainerScheme()

        containerScheme.colorScheme = colorScheme()
        containerScheme.typographyScheme = createTypographyCheme(buttonTextSize: AppConstants.Font.ButtonSmall)

        return containerScheme
    }

    @objc func textFieldContainerScheme() -> MDCContainerScheme {
        let containerScheme = MDCContainerScheme()

        containerScheme.colorScheme = colorScheme()
        containerScheme.typographyScheme = createTypographyCheme()

        return containerScheme
    }

    func borderlessShapeScheme() -> MDCShapeScheme {
        let shapeScheme = MDCShapeScheme(defaults: .material201809)

        return shapeScheme
    }

    func colorScheme() -> MDCSemanticColorScheme {
        let colorScheme = MDCSemanticColorScheme(defaults: .material201907)

        colorScheme.backgroundColor = UIColor.applicationColor(ViewBackground)
        colorScheme.errorColor = UIColor.applicationColor(Destructive)
        colorScheme.onBackgroundColor = UIColor.applicationColor(Destructive)
        colorScheme.onPrimaryColor = UIColor.applicationColor(TextOnPrimary)
//        colorScheme.onSecondaryColor = UIColor.applicationColor(Destructive)
        colorScheme.primaryColor = UIColor.applicationColor(Primary)
        colorScheme.primaryColorVariant = UIColor.applicationColor(PrimaryDark)
//        colorScheme.secondaryColor = UIColor.applicationColor(Destructive)
//        colorScheme.surfaceColor = UIColor.applicationColor(Destructive)

        return colorScheme
    }

    func colorSchemeInverted() -> MDCSemanticColorScheme {
        let colorScheme = MDCSemanticColorScheme(defaults: .material201907)

        colorScheme.primaryColor = UIColor.applicationColor(ViewBackground)
        colorScheme.primaryColorVariant = UIColor.applicationColor(GreyLight)
        colorScheme.onPrimaryColor = UIColor.applicationColor(TextOnPrimary)

        colorScheme.backgroundColor = UIColor.applicationColor(Primary)
        colorScheme.onBackgroundColor = UIColor.applicationColor(Destructive)

        colorScheme.errorColor = UIColor.applicationColor(Destructive)

        return colorScheme
    }
//    func textThemeScheme() -> MDCTextStyle {
//        let style = MDCTextStyle()
//
//        return style
//    }

    @objc func leftRoundedTopCutBottomShapegenerator() -> MDCRectangleShapeGenerator {
        let shapeGenerator = MDCRectangleShapeGenerator()

        let cornerTreatment = MDCCutCornerTreatment(cut: 0.0)

        shapeGenerator.topLeftCorner = MDCRoundedCornerTreatment(radius: 4.0)
        shapeGenerator.topRightCorner = cornerTreatment
        shapeGenerator.bottomLeftCorner = MDCCutCornerTreatment(cut: 4.0)
        shapeGenerator.bottomRightCorner = cornerTreatment

        return shapeGenerator
    }

    @objc func bottomLeftRoundedShapegenerator() -> MDCRectangleShapeGenerator {
        let shapeGenerator = MDCRectangleShapeGenerator()

        let roundedCornerTreatment = MDCRoundedCornerTreatment(radius: 4.0)
        let cornerTreatment = MDCCutCornerTreatment(cut: 0.0)

        shapeGenerator.topLeftCorner = cornerTreatment
        shapeGenerator.topRightCorner = cornerTreatment
        shapeGenerator.bottomLeftCorner = roundedCornerTreatment
        shapeGenerator.bottomRightCorner = cornerTreatment

        return shapeGenerator
    }

    func roundedCornersShapeGenerator(radius: CGFloat) -> MDCRectangleShapeGenerator {
        let shapeGenerator = MDCRectangleShapeGenerator()

        let roundedCornerTreatment = MDCRoundedCornerTreatment(radius: radius)

        shapeGenerator.topLeftCorner = roundedCornerTreatment
        shapeGenerator.topRightCorner = roundedCornerTreatment
        shapeGenerator.bottomLeftCorner = roundedCornerTreatment
        shapeGenerator.bottomRightCorner = roundedCornerTreatment

        return shapeGenerator
    }

    @objc func setupValueFont(textField: MDCTextField) {
        textField.font = fontForSize(size: AppConstants.Font.LabelLarge)
        textField.placeholderLabel.font = fontForSize(size: AppConstants.Font.LabelLarge)
    }

    @objc func setupValueFont(multilineTextField: MDCMultilineTextField) {
        multilineTextField.font = fontForSize(size: AppConstants.Font.LabelLarge)
    }

    @objc func setupLabelFont(label: UILabel) {
        label.font = fontForSize(size: AppConstants.Font.LabelMedium)
    }

    @objc func setupValueFont(label: UILabel) {
        label.font = fontForSize(size: AppConstants.Font.LabelLarge)
    }

    @objc func setupLargeValueFont(label: UILabel) {
        // default font size for values is LabelLarge so use LabelHuge for 'large values'
        label.font = fontForSize(size: AppConstants.Font.LabelHuge)
    }

    @objc func setupEditButtonArea(view: UIView) {
        view.layer.shadowPath = UIBezierPath(roundedRect: view.bounds,
                                             cornerRadius: view.layer.cornerRadius).cgPath
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4.0
        view.layer.masksToBounds = false
    }

    @objc func setupEditSaveButton(button: MDCButton) {
        button.applyContainedTheme(withScheme: primaryButtonScheme())
    }

    @objc func setupEditCancelButton(button: MDCButton) {
        button.applyOutlinedTheme(withScheme: primaryButtonScheme())
        button.setBorderColor(UIColor.applicationColor(Primary), for: .normal)
    }

    @objc func setupCardBoldTextButtonTheme(button: MDCButton) {
        button.applyTextTheme(withScheme: cardButtonSchemeBolded())
    }

    @objc func setupCardTextButtonTheme(button: MDCButton) {
        button.applyTextTheme(withScheme: cardButtonScheme())
    }

    @objc func setupTextButtonTheme(button: MDCButton) {
        button.applyTextTheme(withScheme: textButtonScheme())
        button.setTitleFont(UIFont.init(name: AppConstants.Font.Name, size: AppConstants.Font.ButtonMedium), for: .normal)
    }

    @objc func setupImageButtonTheme(button: MDCButton) {
        button.applyTextTheme(withScheme: imageButtonScheme())
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.imageView?.contentMode = .scaleAspectFit
    }

    @objc func setupPrimaryButtonTheme(button: MDCButton) {
        button.applyContainedTheme(withScheme: primaryButtonScheme())
        button.setTitleFont(UIFont.init(name: AppConstants.Font.Name, size: AppConstants.Font.ButtonMedium), for: .normal)

        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.imageView?.contentMode = .scaleAspectFit
    }

    @objc func setupSecondaryButtonTheme(button: MDCButton) {
        button.applyContainedTheme(withScheme: secondaryButtonScheme())
        button.setTitleFont(UIFont.init(name: AppConstants.Font.Name, size: AppConstants.Font.ButtonMedium), for: .normal)
    }

    @objc func setupSpeciesButtonTheme(button: MDCButton) {
        self.setupPrimaryButtonTheme(button: button)
        button.imageEdgeInsets = UIEdgeInsets(top: -6.0, left: -14.0, bottom: -6.0, right: 0.0)

        button.setBorderColor(UIColor.applicationColor(GreyMedium), for: .disabled)
        button.setBorderWidth(1, for: .disabled)
        button.setBackgroundColor(UIColor.applicationColor(ViewBackground), for: .disabled)
        button.setTitleColor(UIColor.applicationColor(Primary), for: .disabled)
    }

    @objc func setupImagesButtonTheme(button: MDCButton) {
        button.applyOutlinedTheme(withScheme: primaryButtonScheme())
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.imageView?.contentMode = .scaleAspectFit

        button.setBorderColor(UIColor.applicationColor(Primary), for: .normal)
        button.setBorderColor(UIColor.applicationColor(GreyMedium), for: .disabled)
        button.setBorderWidth(1, for: .normal)
        button.setBackgroundColor(UIColor.applicationColor(Primary), for: .normal)
        button.setBackgroundColor(UIColor.applicationColor(ViewBackground), for: .disabled)
        button.setImageTintColor(UIColor.applicationColor(TextOnPrimary), for: .normal)
        button.setImageTintColor(UIColor.applicationColor(GreyMedium), for: .disabled)
    }

    @objc func setupSegmentedController(segmentedController: UISegmentedControl) {
        let font = fontForSize(size: AppConstants.Font.LabelMedium)
        segmentedController.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        segmentedController.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .selected)
        segmentedController.selectedConfiguration()
    }

    @objc func setupAmountTextField(textField: MDCTextField, delegate: UITextFieldDelegate) -> MDCTextInputControllerUnderline {
        textField.delegate = delegate
        textField.keyboardType = .numberPad
        textField.placeholder = nil
        textField.leftView = nil
        textField.leftViewMode = .never
        textField.clearButtonMode = .never
        textField.inputAccessoryView = KeyboardToolbarView.textFieldDoneToolbarView(textField) as? UIView

        let textFieldController = MDCTextInputControllerUnderline(textInput: textField)
        textFieldController.applyTheme(withScheme: AppTheme.shared.textFieldContainerScheme())
        textFieldController.isFloatingEnabled = false

        return textFieldController
    }

    @objc func setupDescriptionTextField(textField: MDCMultilineTextField, delegate: UITextViewDelegate) -> MDCTextInputControllerUnderline {
        textField.textView?.delegate = delegate
        textField.minimumLines = 1;
        textField.clearButtonMode = .never;
        textField.textView!.inputAccessoryView = KeyboardToolbarView.textViewDoneToolbarView(textField.textView) as? UIView

        let textFieldController = MDCTextInputControllerUnderline(textInput: textField)
        textFieldController.isFloatingEnabled = false
        textFieldController.applyTheme(withScheme: AppTheme.shared.textFieldContainerScheme())

        return textFieldController
    }

    @objc func setupNumberTextField(textField: MDCTextField, delegate: UITextFieldDelegate) -> MDCTextInputControllerUnderline {
        textField.delegate = delegate
        textField.clearButtonMode = .never;
        textField.inputAccessoryView = KeyboardToolbarView.textFieldDoneToolbarView(textField) as? UIView

        let textFieldController = MDCTextInputControllerUnderline(textInput: textField)
        textFieldController.isFloatingEnabled = false
        textFieldController.applyTheme(withScheme: AppTheme.shared.textFieldContainerScheme())

        return textFieldController
    }

    private func configureDropDown() {
        DropDown.appearance().cellHeight = AppConstants.UI.ButtonHeightSmall
        DropDown.appearance().textFont = UIFont.appFont(fontSize: AppConstants.Font.LabelMedium)
        DropDown.appearance().textColor = UIColor.applicationColor(TextPrimary)
    }
}
