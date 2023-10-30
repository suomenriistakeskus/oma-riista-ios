import Foundation

extension UIRefreshControl {
    func beginRefreshingProgrammatically() {
        if let scrollView = superview as? UITableView {
            let offsetPoint = CGPoint.init(x: 0, y: -frame.size.height)
            scrollView.setContentOffset(offsetPoint, animated: true)
        }

        beginRefreshing()
        sendActions(for: .valueChanged)
    }
}
