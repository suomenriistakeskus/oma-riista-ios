import Foundation
import DifferenceKit
import RiistaCommon

fileprivate class PointOfInterestItemHolder: Differentiable {
    private(set) var pointOfInterestItem: PoiListItem

    var differenceIdentifier: Int {
        get {
            pointOfInterestItem.id.hashValue
        }
    }

    init(pointOfInterestItem: PoiListItem) {
        self.pointOfInterestItem = pointOfInterestItem
    }

    func isContentEqual(to source: PointOfInterestItemHolder) -> Bool {
        // PoiListItems are data classes in common lib -> use hash
        return pointOfInterestItem.hashValue == source.pointOfInterestItem.hashValue
    }
}

typealias PointOfInterestActionListener = PointOfInterestGroupCellListener & PointOfInterestItemCellListener

class PointOfInterestTableViewController: NSObject, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView? {
        didSet {
            if let tableView = tableView {
                tableView.delegate = self
                tableView.dataSource = self
                registerCells(tableView: tableView)
            }
        }
    }

    weak var actionListener: PointOfInterestActionListener?

    private var pointOfInterestItemHolders: [PointOfInterestItemHolder] = []

    func setPointOfInterestItems(pointOfInterestItems: [PoiListItem]) {
        let newHolders = pointOfInterestItems.map { PointOfInterestItemHolder(pointOfInterestItem: $0) }

        if let tableView = tableView {
            let stagedChangeSet = StagedChangeset(source: self.pointOfInterestItemHolders, target: newHolders)
            tableView.reload(using: stagedChangeSet, with: .fade) { newHolders in
                self.pointOfInterestItemHolders = newHolders
            }
        } else {
            self.pointOfInterestItemHolders = newHolders
            print("Did you forget to set tableView?")
        }
    }

    private func registerCells(tableView: UITableView) {
        tableView.register(PointOfInterestGroupCell.self, forCellReuseIdentifier: PointOfInterestGroupCell.reuseIdentifier)
        tableView.register(PointOfInterestItemCell.self, forCellReuseIdentifier: PointOfInterestItemCell.reuseIdentifier)
        tableView.register(SeparatorCell.self, forCellReuseIdentifier: SeparatorCell.reuseIdentifier)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pointOfInterestItemHolders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let pointOfInterestItem = pointOfInterestItemHolders[indexPath.row].pointOfInterestItem

        if let groupItem = pointOfInterestItem as? PoiListItem.PoiGroupItem {
            return dequeuePoiGroupItem(tableView: tableView, indexPath: indexPath, item: groupItem)
        } else if let poiItem = pointOfInterestItem as? PoiListItem.PoiItem {
            return dequeuePoiItem(tableView: tableView, indexPath: indexPath, item: poiItem)
        } else if let separatorItem = pointOfInterestItem as? PoiListItem.Separator {
            return dequeueSeparatorItem(tableView: tableView, indexPath: indexPath, item: separatorItem)
        } else {
            fatalError("Unexpected PoiItem type!")
        }
    }

    private func dequeuePoiGroupItem(
        tableView: UITableView,
        indexPath: IndexPath,
        item: PoiListItem.PoiGroupItem
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: PointOfInterestGroupCell.reuseIdentifier,
            for: indexPath
        ) as! PointOfInterestGroupCell

        cell.listener = actionListener
        cell.bind(groupItem: item)

        return cell
    }

    private func dequeuePoiItem(
        tableView: UITableView,
        indexPath: IndexPath,
        item: PoiListItem.PoiItem
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: PointOfInterestItemCell.reuseIdentifier,
            for: indexPath
        ) as! PointOfInterestItemCell

        cell.listener = actionListener
        cell.bind(poiItem: item)

        return cell
    }

    private func dequeueSeparatorItem(
        tableView: UITableView,
        indexPath: IndexPath,
        item: PoiListItem.Separator
    ) -> UITableViewCell {
        return tableView.dequeueReusableCell(
            withIdentifier: SeparatorCell.reuseIdentifier,
            for: indexPath
        )
    }
}
