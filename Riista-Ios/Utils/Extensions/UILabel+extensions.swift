import Foundation

extension UILabel {

    @discardableResult
    @objc func configureCompat(for usage: AppConstants.FontUsage) -> Self {
        return configure(for: usage)
    }

    @discardableResult
    func configure(
        for usage: AppConstants.FontUsage,
        fontWeight: UIFont.Weight = .regular,
        textColor: UIColor = UIColor.applicationColor(TextPrimary),
        textAlignment: NSTextAlignment = .left,
        numberOfLines: Int = 1
    ) -> Self {
        return configure(
            fontSize: usage.toSizePoints(),
            fontWeight: fontWeight,
            textColor: textColor,
            textAlignment: textAlignment,
            numberOfLines: numberOfLines
        )
    }

    @discardableResult
    func configure(
        fontSize: AppConstants.FontSize,
        fontWeight: UIFont.Weight = .regular,
        textColor: UIColor = UIColor.applicationColor(TextPrimary),
        textAlignment: NSTextAlignment = .left,
        numberOfLines: Int = 1
    ) -> Self  {
        configure(
            fontSize: fontSize.toSizePoints(),
            fontWeight: fontWeight,
            textColor: textColor,
            textAlignment: textAlignment,
            numberOfLines: numberOfLines
        )
    }

    @discardableResult
    func configure(
        fontSize: CGFloat,
        fontWeight: UIFont.Weight = .regular,
        textColor: UIColor = UIColor.applicationColor(TextPrimary),
        textAlignment: NSTextAlignment = .left,
        numberOfLines: Int = 1
    ) -> Self {
        self.font = UIFont.appFont(fontSize: fontSize, fontWeight: fontWeight)
        self.textColor = textColor
        self.textAlignment = textAlignment
        self.numberOfLines = numberOfLines

        return self
    }
}
