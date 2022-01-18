import Foundation

extension UITextField {
    func usePadding(_ padding: CGFloat? = nil,
                    leftMode: UITextField.ViewMode = .always,
                    rightMode: UITextField.ViewMode = .unlessEditing) {
        usePadding(left: padding, leftMode: leftMode, right: padding, rightMode: rightMode)
    }

    func usePadding(left: CGFloat? = nil, leftMode: UITextField.ViewMode = .always,
                    right: CGFloat? = nil, rightMode: UITextField.ViewMode = .unlessEditing) {
        if let left = left {
            leftView = UIView(frame: CGRect(x: 0, y: 0, width: left, height: 1))
            leftViewMode = leftMode
        } else {
            leftView = nil
            leftViewMode = .never
        }

        if let right = right {
            rightView = UIView(frame: CGRect(x: 0, y: 0, width: right, height: 1))
            rightViewMode = rightMode
        } else {
            rightView = nil
            rightViewMode = .never
        }
    }
}
