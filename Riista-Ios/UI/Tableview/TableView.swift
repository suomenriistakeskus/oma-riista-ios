import Foundation

class TableView: UITableView {

    /**
     * Are we currently layouting subviews (i.e. cells)?
     */
    private(set) var layoutingSubviews: Bool = false

    /**
     * Have any of the cells requested a layout pass?
     */
    private(set) var cellsNeedsLayout: Bool = false

    private(set) var animateCellLayoutChanges: Bool = false

    private var loadIndicatorViewController: LoadIndicatorViewController?

    /**
     * Called when window has been set
     */
    var onWindowSet: (() -> Void)?

    func showLoading() {
        guard let viewController = self.parentViewController else { return }
        loadIndicatorViewController = LoadIndicatorViewController()
            .showIn(parentViewController: viewController, viewToOverlay: self)
    }

    func hideLoading(_ completion: OnCompleted? = nil) {
        loadIndicatorViewController?.hide(completion)
        loadIndicatorViewController = nil
    }

    func setCellNeedsLayout(cell: TableViewCell, animateChanges: Bool) {
        cellsNeedsLayout = true
        self.animateCellLayoutChanges = animateChanges

        if (!layoutingSubviews) {
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        layoutingSubviews = true

        if (cellsNeedsLayout) {
            cellsNeedsLayout = false

            if (animateCellLayoutChanges) {
                performCellLayoutUpdates(animateChanges: true)
            }
        }

        super.layoutSubviews()

        // it is possible that cells require an additional layout pass since e.g. UITableViewCell
        // height cannot be changed from within cell once it has been layouted
        // e.g. https://stackoverflow.com/questions/21396907/how-to-programmatically-increase-uitableview-cells-height-in-iphone/45424594
        //
        // This is the case when we need the initial layout pass to determine how the cell should be
        // layouted. If we then modify any of the constraints (or change stackview axis) we need
        // a second layout pass to update the changes
        if (cellsNeedsLayout) {
            cellsNeedsLayout = false
            performCellLayoutUpdates(animateChanges: animateCellLayoutChanges)
        }

        layoutingSubviews = false
    }

    private func performCellLayoutUpdates(animateChanges: Bool) {
        if (!animateChanges) {
            UIView.setAnimationsEnabled(false)
        }

        // According to apple documentation we can use beginUpdates() "method followed by the endUpdates() method
        // to animate the change in the row heights without reloading the cell".
        // -> same applies for other layout changes that may affect cell appearance
        //
        // https://developer.apple.com/documentation/uikit/uitableview/1614908-beginupdates
        beginUpdates()
        endUpdates()

        if (!animateChanges) {
            UIView.setAnimationsEnabled(true)
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if (window != nil) {
            onWindowSet?()
        }
    }
}
