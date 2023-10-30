extension UIBarButtonItem {
    /**
     * iOS 16 introduces isHidden for UIBarButtonItems. Provide a compatibility field for older iOS versions.
     */
    @objc var isHiddenCompat: Bool {
        get {
            if #available(iOS 16.0, *) {
                return isHidden
            } else {
                return !isEnabled && tintColor == .clear
            }
        }
        set {
            if #available(iOS 16.0, *) {
                isHidden = newValue
            } else {
                tintColor = newValue ? .clear : nil
                isEnabled = !newValue
            }
        }
    }
}
