extension NSString {
    @objc func isAllDigitsOrEmpty() -> Bool {
        let nonNumber = NSCharacterSet.decimalDigits.inverted
        let range = self.rangeOfCharacter(from: nonNumber)

        return range.location == NSNotFound
    }
}
