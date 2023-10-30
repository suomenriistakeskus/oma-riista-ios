import Foundation

/**
 * A `UIBarButtonItem` that has extra flag for hiding.
 *
 * It seems that utilizing isHidden flag is not reliable. Also hiding UIBarButtonItem using isHidden only hides the button
 * but button still reserves space from the nav bar.
 */
class HideableUIBarButtonItem: UIBarButtonItem {
    var shouldBeHidden: Bool = false {
        didSet {
            onShouldBeHiddenChanged?()
        }
    }

    var onShouldBeHiddenChanged: OnChanged? = nil
}

extension Array where Element == HideableUIBarButtonItem {
    var visibleButtons: [UIBarButtonItem] {
        compactMap { button in
            if button.shouldBeHidden {
                return nil
            } else {
                return button
            }
        }
    }
}
