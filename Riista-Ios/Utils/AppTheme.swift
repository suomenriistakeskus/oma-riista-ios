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

    func createTypographyCheme(buttonTextSize: CGFloat = AppConstants.FontUsage.button.toSizePoints(), bolded: Bool = false) -> MDCTypographyScheme {
        let scheme = MDCTypographyScheme()

        let headLineSize = AppConstants.FontUsage.title.fontSize()
        let labelSize = AppConstants.FontUsage.label.fontSize()
        scheme.headline1 = fontForSize(size: headLineSize, bolded: bolded)
        scheme.headline2 = fontForSize(size: headLineSize, bolded: bolded)
        scheme.headline3 = fontForSize(size: headLineSize, bolded: bolded)
        scheme.headline4 = fontForSize(size: headLineSize, bolded: bolded)
        scheme.headline5 = fontForSize(size: headLineSize, bolded: bolded)
        scheme.headline6 = fontForSize(size: headLineSize, bolded: bolded)
        scheme.subtitle1 = fontForSize(size: headLineSize, bolded: bolded)
        scheme.subtitle2 = fontForSize(size: headLineSize, bolded: bolded)
        scheme.body1 = fontForSize(size: labelSize, bolded: bolded)
        scheme.body2 = fontForSize(size: labelSize, bolded: bolded)
        scheme.caption = fontForSize(size: labelSize, bolded: bolded)
        scheme.button = fontForSize(size: buttonTextSize, bolded: bolded)
        scheme.overline = fontForSize(size: labelSize, bolded: bolded)

        return scheme
    }

    @objc func fontForSize(size: AppConstants.FontSize, bolded: Bool = false) -> UIFont {
        return fontForSize(size: size.toSizePoints(), bolded: bolded)
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
        containerScheme.typographyScheme = createTypographyCheme(bolded: true)

        return containerScheme
    }

    func outlineButtonSchemeSmall() -> MDCContainerScheme {
        let containerScheme = MDCContainerScheme()

        containerScheme.colorScheme = colorScheme()
        containerScheme.typographyScheme = createTypographyCheme(buttonTextSize: AppConstants.FontSize.small.toSizePoints())

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
        containerScheme.typographyScheme = createTypographyCheme(buttonTextSize: AppConstants.FontSize.small.toSizePoints())

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
        button.setTitleFont(UIFont.appFont(for: .button), for: .normal)
    }

    @objc func setupImageButtonTheme(button: MDCButton) {
        button.applyTextTheme(withScheme: imageButtonScheme())
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.imageView?.contentMode = .scaleAspectFit
    }

    @objc func setupPrimaryButtonTheme(button: MDCButton) {
        button.applyContainedTheme(withScheme: primaryButtonScheme())
        button.setTitleFont(UIFont.appFont(for: .button), for: .normal)

        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.imageView?.contentMode = .scaleAspectFit
    }

    @objc func setupSecondaryButtonTheme(button: MDCButton) {
        button.applyContainedTheme(withScheme: secondaryButtonScheme())
        button.setTitleFont(UIFont.appFont(for: .button), for: .normal)
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
        let font = fontForSize(size: .medium)
        segmentedController.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        segmentedController.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .selected)
        segmentedController.selectedConfiguration()
    }

    @objc func setupAmountTextField(textField: MDCUnderlinedTextField, delegate: UITextFieldDelegate) {
        textField.configure(for: .inputValue)
        textField.delegate = delegate
        textField.keyboardType = .numberPad
        textField.placeholder = nil
        textField.leftView = nil
        textField.leftViewMode = .never
        textField.clearButtonMode = .never
        textField.inputAccessoryView = KeyboardToolbarView.textFieldDoneToolbarView(textField) as? UIView

        textField.labelBehavior = .disappears
    }

    @objc func setupDescriptionTextArea(_ textArea: MDCFilledTextArea, delegate: UITextViewDelegate) {
        themeUnderlinedTextArea(textArea, for: .inputValue, backgroundColor: UIColor.applicationColor(ViewBackground))

        textArea.labelBehavior = .disappears

        textArea.textView.delegate = delegate
        textArea.textView.inputAccessoryView = KeyboardToolbarView.textViewDoneToolbarView(textArea.textView) as? UIView

        textArea.clipsToBounds = true
        textArea.minimumNumberOfVisibleRows = 1
        textArea.maximumNumberOfVisibleRows = 5
    }

    private func configureDropDown() {
        DropDown.appearance().cellHeight = AppConstants.UI.ButtonHeightSmall
        DropDown.appearance().textFont = UIFont.appFont(for: .label)
        DropDown.appearance().textColor = UIColor.applicationColor(TextPrimary)
    }

    func themeUnderlinedTextField(
        _ field: MDCUnderlinedTextField,
        for usage: AppConstants.FontUsage,
        backgroundColor: UIColor
    ) {
        field.font = UIFont.appFont(for: usage)
        if let textControl = field as? MDCTextControl {
            // override container style in order to override floating label font size
            textControl.containerStyle = UnderlinedTextFieldStyle()
        }

        field.leadingEdgePaddingOverride = 0
        field.trailingEdgePaddingOverride = 0
        field.verticalDensity = 1

        field.setUnderlineColor(UIColor.applicationColor(Primary), for: .editing)
        field.setUnderlineColor(UIColor.applicationColor(GreyDark), for: .normal)
        field.setUnderlineColor(UIColor.applicationColor(GreyMedium), for: .disabled)

        field.setNormalLabelColor(UIColor.applicationColor(Primary), for: .editing)
        field.setNormalLabelColor(UIColor.applicationColor(GreyDark), for: .normal)
        field.setNormalLabelColor(UIColor.applicationColor(GreyMedium), for: .disabled)

        field.setFloatingLabelColor(UIColor.applicationColor(Primary), for: .editing)
        field.setFloatingLabelColor(UIColor.applicationColor(GreyDark), for: .normal)
        field.setFloatingLabelColor(UIColor.applicationColor(GreyMedium), for: .disabled)
    }

    func themeUnderlinedTextArea(
        _ area: MDCFilledTextArea,
        for usage: AppConstants.FontUsage,
        backgroundColor: UIColor
    ) {
        area.textView.font = UIFont.appFont(for: usage)

        // textview is masked for some reason. This appears as if first letters are only partially visible
        // when leading/trailing paddings are set to 0 (first letters have alpha of 50% or something).
        // -> Remove mask by adding textView as direct subview to area
        //
        // see: https://github.com/material-components/material-components-ios/blob/08d01596dfd0d79581b58b563e69a1d1f6ff109f/components/TextControls/src/BaseTextAreas/MDCBaseTextArea.m#L158
        area.textView.removeFromSuperview()
        area.addSubview(area.textView)

        area.leadingEdgePaddingOverride = 0
        area.trailingEdgePaddingOverride = 0
        area.verticalDensity = 1

        area.setFilledBackgroundColor(backgroundColor, for: .editing)
        area.setFilledBackgroundColor(backgroundColor, for: .normal)
        area.setFilledBackgroundColor(backgroundColor, for: .disabled)

        area.placeholderColor = UIColor.applicationColor(GreyDark)

        area.setUnderlineColor(UIColor.applicationColor(Primary), for: .editing)
        area.setUnderlineColor(UIColor.applicationColor(GreyDark), for: .normal)
        area.setUnderlineColor(UIColor.applicationColor(GreyMedium), for: .disabled)

        area.setNormalLabel(UIColor.applicationColor(Primary), for: .editing)
        area.setNormalLabel(UIColor.applicationColor(GreyDark), for: .normal)
        area.setNormalLabel(UIColor.applicationColor(GreyMedium), for: .disabled)

        area.setFloatingLabel(UIColor.applicationColor(Primary), for: .editing)
        area.setFloatingLabel(UIColor.applicationColor(GreyDark), for: .normal)
        area.setFloatingLabel(UIColor.applicationColor(GreyMedium), for: .disabled)
    }
}

extension MDCUnderlinedTextField {
    @discardableResult
    @objc func configure(
        for usage: AppConstants.FontUsage
    ) -> Self {
        return configure(for: usage, backgroundColor: UIColor.applicationColor(ViewBackground))
    }

    @discardableResult
    @objc func configure(
        for usage: AppConstants.FontUsage,
        backgroundColor: UIColor
    ) -> Self {
        AppTheme.shared.themeUnderlinedTextField(self, for: usage, backgroundColor: backgroundColor)
        return self
    }
}

fileprivate class UnderlinedTextFieldStyle: MDCTextControlStyleUnderlined {
    override func floatingFont(withNormalFont font: UIFont) -> UIFont {
        return font.withSize(AppConstants.FontSize.medium.toSizePoints())
    }
}
