extension UISegmentedControl {

    func selectedConfiguration() {
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        setTitleTextAttributes(titleTextAttributes, for: .selected)
    }
}
