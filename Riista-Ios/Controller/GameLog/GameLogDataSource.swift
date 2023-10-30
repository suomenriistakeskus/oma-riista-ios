import Foundation
import RiistaCommon

protocol GameLogDataSourceListener: EntityDataSourceListener {
    func onHarvestClicked(harvest: CommonHarvest)
    func onObservationClicked(observation: CommonObservation)
    func onSrvaClicked(srva: CommonSrvaEvent)
}

class GameLogDataSource: UnifiedEntityDataSource {

    private lazy var gameLogTableViewController: GameLogTableViewController = {
        GameLogTableViewController(gameLogDataSource: self)
    }()

    weak var listener: GameLogDataSourceListener?

    var tableView: UITableView? {
        didSet {
            tableView?.dataSource = gameLogTableViewController
            tableView?.delegate = gameLogTableViewController
            shouldReloadData = true
        }
    }

    init() {
        super.init(
            onlyEntitiesWithImages: false,
            supportedDataSourceTypes: [.harvest, .observation, .srva]
        )
    }

    override func reloadContent(_ onCompleted: OnCompleted? = nil) {
        fetchEntitiesAndReloadTableviewData(onCompleted)
    }

    override func onFilterApplied(dataSourceChanged: Bool, filteredDataChanged: Bool) {
        if (!dataSourceChanged && !filteredDataChanged && !shouldReloadData) {
            print("No need to reload tableview data!")
            return
        }

        shouldReloadData = false

        fetchEntitiesAndReloadTableviewData()
    }

    private func fetchEntitiesAndReloadTableviewData(_ onCompleted: OnCompleted? = nil) {
        guard let dataSource = activeDataSource else {
            print("No data source, cannot fetch entities!")
            return
        }

        dataSource.fetchEntities()
    }


    // MARK: EntityDataSourceListener

    override func onDataSourceDataUpdated(for entityType: FilterableEntityType) {
        guard let currentEntityType = activeDataSource?.filteredEntityType, currentEntityType == entityType else {
            return
        }

        self.tableView?.reloadData()
        self.listener?.onDataSourceDataUpdated(for: entityType)
    }
}

// data source + delegate for the tableview in a separate class as it needs to inherit NSObject
fileprivate class GameLogTableViewController: NSObject, UITableViewDataSource, UITableViewDelegate {
    let gameLogDataSource: GameLogDataSource

    private var dataSource: FilterableEntityDataSource? {
        get {
            gameLogDataSource.activeDataSource
        }
    }

    init(gameLogDataSource: GameLogDataSource) {
        self.gameLogDataSource = gameLogDataSource
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        dataSource?.getSectionCount() ?? 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let monthNameHeader = tableView.dequeueReusableCell(withIdentifier: "GameLogHeaderCell") as! GameLogHeaderCell
        monthNameHeader.frame = CGRect(
            x: 0,
            y: 0,
            width: tableView.frame.size.width,
            height: monthNameHeader.frame.size.height
        )

        monthNameHeader.monthLabel.text = dataSource?.getSectionName(sectionIndex: section) ?? "-"

        monthNameHeader.timeLine.isHidden = section == 0
        return monthNameHeader
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource?.getSectionEntityCount(sectionIndex: section) ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameLogItemCell") as! GameLogItemCell
        cell.frame = CGRect(
            x: 0,
            y: 0,
            width: tableView.frame.size.width,
            height: cell.frame.size.height
        )

        let isFirst = indexPath.section == 0 && indexPath.row == 0
        let isLast = indexPath.section == tableView.numberOfSections - 1 &&
            indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1

        if let filteredEntityType = dataSource?.filteredEntityType {
            switch filteredEntityType {
            case .harvest:
                if let harvest = gameLogDataSource.getHarvest(specifiedBy: .indexPath(indexPath)) {
                    cell.setupFromHarvest(harvest: harvest, isFirst: isFirst, isLast: isLast)
                }
            case .observation:
                if let observation = gameLogDataSource.getObservation(specifiedBy: .indexPath(indexPath)) {
                    cell.setupFromObservation(observation: observation, isFirst: isFirst, isLast: isLast)
                }
            case .srva:
                if let srva = gameLogDataSource.getSrva(specifiedBy: .indexPath(indexPath)) {
                    cell.setupFromSrva(srva: srva, isFirst: isFirst, isLast: isLast)
                }
            case .pointOfInterest:
                print("Cannot display points-of-interest in game log")
                break
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let filteredEntityType = dataSource?.filteredEntityType {
            switch filteredEntityType {
            case .harvest:
                if let harvest = gameLogDataSource.getHarvest(specifiedBy: .indexPath(indexPath)) {
                    gameLogDataSource.listener?.onHarvestClicked(harvest: harvest)
                }
            case .observation:
                if let observation = gameLogDataSource.getObservation(specifiedBy: .indexPath(indexPath)) {
                    gameLogDataSource.listener?.onObservationClicked(observation: observation)
                }
            case .srva:
                if let srva = gameLogDataSource.getSrva(specifiedBy: .indexPath(indexPath)) {
                    gameLogDataSource.listener?.onSrvaClicked(srva: srva)
                }
            case .pointOfInterest:
                print("Cannot display points-of-interest in game log")
                break
            }
        }
    }
}
