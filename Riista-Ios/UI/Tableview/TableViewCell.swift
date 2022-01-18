import Foundation

class TableViewCell: UITableViewCell {
    weak var tableView: TableView?

    /**
     * Attempts to notify the UITableView that the cell needs a layout. UITableViewCells are unable to update
     * e.g. their heights by themselves and thus they need to notify tableview in such cases.
     */
    func setCellNeedsLayout(animateChanges: Bool) {
        setNeedsLayout()
        tableView?.setCellNeedsLayout(cell: self, animateChanges: animateChanges)
    }
}
