import Foundation


class TextField: UITextField {
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()

        // text jumps at least on iOS 10 unless layoutIfNeeded is called
        // - https://stackoverflow.com/a/33334567
        layoutIfNeeded()

        return result
    }
}
