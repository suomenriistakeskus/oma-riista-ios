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

    func setTextAllowingOrphanLines(text: String) {
        // according to https://stackoverflow.com/a/65025926
        //
        // don't try to prevent orphan lines. Without this text can be broken to multiple lines even
        // when dates could have fitted in the first line e.g.
        //
        // |        <total available space>        |
        // | Pienpetokausi                         |
        // | 1.8.2019-30.4.2020, 4949110101        |
        if #available(iOS 14.0, *) {
            lineBreakStrategy.remove(.pushOut)
            self.text = text
        } else {
            let paragrapStyle = NSMutableParagraphStyle()
            paragrapStyle.lineBreakStrategy.remove(.pushOut)

            attributedText = text.toAttributedString([.paragraphStyle: paragrapStyle])
        }
    }
}
