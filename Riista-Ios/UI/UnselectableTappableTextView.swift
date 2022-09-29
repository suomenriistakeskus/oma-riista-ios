import Foundation

class UnselectableTappableTextView: UITextView {
    // required to prevent blue background selection from any situation
    override var selectedTextRange: UITextRange? {
        get { return nil }
        set {}
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        if let tapGestureRecognizer = gestureRecognizer as? UITapGestureRecognizer,
            tapGestureRecognizer.numberOfTapsRequired == 1 {
            // required for compatibility with links
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }

        return false
    }
}
