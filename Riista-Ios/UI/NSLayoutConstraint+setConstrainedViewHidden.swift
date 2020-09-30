import Foundation


extension NSLayoutConstraint
{
    /** Changes the visiblity of the constrained view assuming preconditions are met.
     *
     * In addition to this constraint there should be a second constraint in the UI which dictates the actual
     * height for the view (it's priority should be set to UILayoutPriorityDefaultHigh (750).
     */
    @objc func setConstrainedViewHidden(hidden: Bool) {
        // Hide constrained view by adjusting priorities (and setting height to 0).
        //
        // Explicitly use priorities for changing the height of the view. It seems that
        // toggling isActive state of the constraint also works but setting .active = NO calls
        // removeConstraint() method under the hood. This may cause the constraint to be garbage
        // collected (if held in a weak property) even though this behaviour has not been observed
        // during tests. Toggling active state may also cause auto layout issues in some cases
        // --> altering priorities if probably better
        // https://developer.apple.com/documentation/uikit/nslayoutconstraint/1527000-isactive
        if (hidden) {
            self.priority = UILayoutPriority.defaultHigh + 1
            self.constant = 0
        } else {
            self.priority = UILayoutPriority.defaultHigh - 1
        }
    }
}
