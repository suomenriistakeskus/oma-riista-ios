import Foundation
import DifferenceKit
import RiistaCommon

class MapClusteredItemsTableViewController: NSObject, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView? {
        didSet {
            if let tableView = tableView {
                tableView.delegate = self
                tableView.dataSource = self
                registerCells(tableView: tableView)
            }
        }
    }

    weak var harvestClickHandler: MapHarvestCellClickHandler?
    weak var observationClickHandler: MapObservationCellClickHandler?
    weak var srvaClickHandler: MapSrvaCellClickHandler?
    weak var pointOfInterestClickHandler: MapPointOfInterestCellClickHandler?

    private var clusteredItems: [MapClusteredItemViewModel] = []

    func setClusteredItems(items: [MapClusteredItemViewModel]) {
        if let tableView = tableView {
            let stagedChangeSet = StagedChangeset(source: self.clusteredItems, target: items)
            tableView.reload(using: stagedChangeSet, with: .fade) { newHolders in
                self.clusteredItems = items
            }
        } else {
            self.clusteredItems = items
            print("Did you forget to set tableView?")
        }
    }

    private func registerCells(tableView: UITableView) {
        tableView.register(MapHarvestCell.self, forCellReuseIdentifier: MapHarvestCell.reuseIdentifier)
        tableView.register(MapObservationCell.self, forCellReuseIdentifier: MapObservationCell.reuseIdentifier)
        tableView.register(MapSrvaCell.self, forCellReuseIdentifier: MapSrvaCell.reuseIdentifier)
        tableView.register(MapPointOfInterestCell.self, forCellReuseIdentifier: MapPointOfInterestCell.reuseIdentifier)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        clusteredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let clusteredItem = clusteredItems[indexPath.row]
        switch clusteredItem.itemType {
        case .harvest:
            return dequeueMapHarvestCell(tableView: tableView, indexPath: indexPath, clusteredItem: clusteredItem)
        case .observation:
            return dequeueMapObservationCell(tableView: tableView, indexPath: indexPath, clusteredItem: clusteredItem)
        case .srva:
            return dequeueMapSrvaCell(tableView: tableView, indexPath: indexPath, clusteredItem: clusteredItem)
        case .pointOfInterest:
            return dequeueMapPointOfInterestCell(tableView: tableView, indexPath: indexPath, clusteredItem: clusteredItem)
        }
    }

    private func dequeueMapHarvestCell(
        tableView: UITableView,
        indexPath: IndexPath,
        clusteredItem: MapClusteredItemViewModel
    ) -> UITableViewCell {
        guard let harvestViewModel = clusteredItem as? MapHarvestViewModel else {
            fatalError("Clustered item not harvest!")
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: MapHarvestCell.reuseIdentifier,
            for: indexPath
        ) as! MapHarvestCell

        cell.clickHandler = harvestClickHandler
        cell.bind(harvestViewModel: harvestViewModel)

        return cell
    }

    private func dequeueMapObservationCell(
        tableView: UITableView,
        indexPath: IndexPath,
        clusteredItem: MapClusteredItemViewModel
    ) -> UITableViewCell {
        guard let observationViewModel = clusteredItem as? MapObservationViewModel else {
            fatalError("Clustered item not observation!")
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: MapObservationCell.reuseIdentifier,
            for: indexPath
        ) as! MapObservationCell

        cell.clickHandler = observationClickHandler
        cell.bind(observationViewModel: observationViewModel)

        return cell
    }

    private func dequeueMapSrvaCell(
        tableView: UITableView,
        indexPath: IndexPath,
        clusteredItem: MapClusteredItemViewModel
    ) -> UITableViewCell {
        guard let srvaViewModel = clusteredItem as? MapSrvaViewModel else {
            fatalError("Clustered item not srva!")
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: MapSrvaCell.reuseIdentifier,
            for: indexPath
        ) as! MapSrvaCell

        cell.clickHandler = srvaClickHandler
        cell.bind(srvaViewModel: srvaViewModel)

        return cell
    }

    private func dequeueMapPointOfInterestCell(
        tableView: UITableView,
        indexPath: IndexPath,
        clusteredItem: MapClusteredItemViewModel
    ) -> UITableViewCell {
        guard let pointOfInterestViewModel = clusteredItem as? MapPointOfInterestViewModel else {
            fatalError("Clustered item not point of interest!")
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: MapPointOfInterestCell.reuseIdentifier,
            for: indexPath
        ) as! MapPointOfInterestCell

        cell.clickHandler = pointOfInterestClickHandler
        cell.bind(viewModel: pointOfInterestViewModel)

        return cell
    }
}
