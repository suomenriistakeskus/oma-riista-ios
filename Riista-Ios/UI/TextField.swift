import Foundation


class TextField: UITextField {

    init(addInputAccessoryView: Bool = true) {
        super.init(frame: .zero)
        setup(addInputAccessoryView: addInputAccessoryView)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup(addInputAccessoryView: true)
    }


    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(addInputAccessoryView: true)
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()

        // text jumps at least on iOS 10 unless layoutIfNeeded is called
        // - https://stackoverflow.com/a/33334567
        layoutIfNeeded()

        return result
    }

    func setup(addInputAccessoryView: Bool) {
        if (addInputAccessoryView) {
            self.inputAccessoryView = KeyboardToolBar().hideKeyboardOnDone(editView: self)
        } else {
            inputAccessoryView = nil
        }
    }
}
