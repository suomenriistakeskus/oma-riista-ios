import Foundation

extension UIFont {
    static func appFont(
        fontSize: CGFloat,
        fontWeight: UIFont.Weight = .regular
    ) -> UIFont {
        var fontAttributes: [UIFontDescriptor.AttributeName : Any] = [:]
        fontAttributes[.size] = fontSize

        var traits = (fontAttributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
        traits[UIFontDescriptor.TraitKey.weight] = fontWeight
        fontAttributes[.traits] = traits

        return appFont(fontAttributes: fontAttributes)
    }

    static func appFont(fontAttributes: [UIFontDescriptor.AttributeName : Any]) -> UIFont {
        var fontAttributes = fontAttributes
        fontAttributes[.family] = AppConstants.Font.Name

        var traits = (fontAttributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
        let fontWeightFromTraits: UIFont.Weight? = traits[UIFontDescriptor.TraitKey.weight] as? UIFont.Weight

        // it seems that application font does not support usage attribute. Remove it
        // and replace it with appropriate font weight
        var fontWeightOverride: UIFont.Weight? = nil
        if let usageAttr = fontAttributes.removeValue(forKey: .nsctFontUIUsage) as? String {
            switch usageAttr {
            case "CTFontEmphasizedUsage":
                fontWeightOverride = .semibold
                break
            case "CTFontBoldUsage":
                fontWeightOverride = .bold
                break
            case "CTFontRegularUsage":
                fallthrough
            default:
                // don't update weight
                break
            }
        }

        // ensure font weight is set. We're obtaining the font based on .family and thus
        // font weight is essential in determining what font will be used:
        // https://stackoverflow.com/a/34585139
        let newFontWeight = fontWeightOverride ?? fontWeightFromTraits ?? .regular
        traits[UIFontDescriptor.TraitKey.weight] = newFontWeight
        fontAttributes[.traits] = [UIFontDescriptor.TraitKey.weight: newFontWeight]

        let font = UIFont(descriptor: UIFontDescriptor(fontAttributes: fontAttributes), size: 0)
        return font
    }

    func withTraits(symbolicTraits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        if let descriptor = fontDescriptor.withSymbolicTraits(symbolicTraits) {
            return UIFont(descriptor: descriptor, size: 0)
        }
        print("Failed to instantiate font with traits: \(symbolicTraits)")
        return self
    }

    func bold() -> UIFont {
        let font = withTraits(symbolicTraits: .traitBold)
        return font
    }

    func appFontWithSameAttributes() -> UIFont {
        // nothing to do if already app font
        if (self.familyName == AppConstants.Font.Name) {
            return self
        }

        var fontAttributes = fontDescriptor.fontAttributes
        fontAttributes[.name] = AppConstants.Font.Name

        var fontWeightTrait: UIFont.Weight = .regular
        // it seems that application font does not support usage attribute. Remove it
        // and replace it with appropriate font weight
        if let usageAttr = fontAttributes.removeValue(forKey: .nsctFontUIUsage) as? String {
            switch usageAttr {
            case "CTFontEmphasizedUsage":
                fontWeightTrait = .semibold
                break
            case "CTFontBoldUsage":
                fontWeightTrait = .bold
                break
            case "CTFontRegularUsage":
                fallthrough
            default:
                fontWeightTrait = .regular
            }
        }
        var traits = (fontAttributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
        traits[UIFontDescriptor.TraitKey.weight] = fontWeightTrait
        fontAttributes[.traits] = [UIFontDescriptor.TraitKey.weight: fontWeightTrait]

        return UIFont(descriptor: UIFontDescriptor(fontAttributes: fontAttributes), size: 0)
    }
}

extension UIFontDescriptor.AttributeName {
    static let nsctFontUIUsage = UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")
}
