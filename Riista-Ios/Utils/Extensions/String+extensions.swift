import Foundation

extension String {
    func prefixed(with prefix: String) -> String {
        "\(prefix)\(self)"
    }

    func toAttributedString(_ attributes: [NSAttributedString.Key : Any]? = nil) -> NSAttributedString {
        NSAttributedString(string: self, attributes: attributes)
    }

    func getPreferredSize(font: UIFont?) -> CGSize {
        let attributes: [NSAttributedString.Key : Any]
        if let font = font {
            attributes = [.font : font]
        } else {
            attributes = [:]
        }

        return (self as NSString).size(withAttributes: attributes)
    }

    func getPreferredSize(font: UIFont?, maxWidth: CGFloat) -> CGSize {
        let attributes: [NSAttributedString.Key : Any]
        if let font = font {
            attributes = [.font : font]
        } else {
            attributes = [:]
        }

        let targetRect = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)

        return self.boundingRect(
            with: targetRect,
            options: [.usesFontLeading, .usesLineFragmentOrigin],
            attributes: attributes,
            context: nil
        ).size
    }

    func substringAfter(needle: Character) -> Substring {
        if let needleIndex = firstIndex(of: needle) {
            return self[index(after: needleIndex)..<endIndex]
        }
        return ""
    }

    private static let _dotNumberFormatter = NumberFormatter().apply { numberFormatter in
        numberFormatter.decimalSeparator = "."
    }
    private static let _commaNumberFormatter = NumberFormatter().apply { numberFormatter in
        numberFormatter.decimalSeparator = ","
    }

    func parseDouble() -> Double? {
        return String._commaNumberFormatter.number(from: self)?.doubleValue ??
            String._dotNumberFormatter.number(from: self)?.doubleValue
    }

    func toNotificationName() -> Notification.Name {
        Notification.Name(rawValue: self)
    }
}

extension NSAttributedString {
    func appending(_ attributedString: NSAttributedString) -> NSMutableAttributedString {
        let result: NSMutableAttributedString
        if let mutableSelf = self as? NSMutableAttributedString {
            result = mutableSelf
        } else {
            result = NSMutableAttributedString(attributedString: self)
        }

        result.append(attributedString)
        return result
    }
}

