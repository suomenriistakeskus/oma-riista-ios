import Foundation
import RiistaCommon

typealias ListMapEntriesViewControllerListener = MapHarvestCellClickHandler & MapObservationCellClickHandler &
    MapSrvaCellClickHandler & MapPointOfInterestCellClickHandler

class ListMapEntriesViewController: UIViewController, ProvidesNavigationController, ContainsTableViewForBottomsheet {

    private let clusteredItems: ClusteredMapItems
    private let mapDataSource: MapDataSource
    private weak var listener: ListMapEntriesViewControllerListener?

    private lazy var tableViewController: MapClusteredItemsTableViewController = {
        let controller = MapClusteredItemsTableViewController()

        controller.harvestClickHandler = listener
        controller.observationClickHandler = listener
        controller.srvaClickHandler = listener
        controller.pointOfInterestClickHandler = listener

        return controller
    }()

    internal lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = AppConstants.UI.DefaultButtonHeight
        tableView.rowHeight = UITableView.automaticDimension

        tableViewController.tableView = tableView

        return tableView
    }()

    init(clusteredItems: ClusteredMapItems,
         mapDataSource: MapDataSource,
         listener: ListMapEntriesViewControllerListener
    ) {
        self.clusteredItems = clusteredItems
        self.mapDataSource = mapDataSource
        self.listener = listener

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.applicationColor(ViewBackground)

        let labelContainer = UIView()
        view.addSubview(labelContainer)
        labelContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
        }

        labelContainer.addSeparatorToBottom()

        let label = UILabel()
        label.font = UIFont.appFont(for: .label, fontWeight: .semibold)
        label.text = "MapLocationEntries".localized()
        label.textColor = UIColor.applicationColor(TextPrimary)
        labelContainer.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppConstants.UI.DefaultHorizontalInset)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(labelContainer.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchEntries()
    }

    private func fetchEntries() {
        let clusteredItems = (createHarvestViewModels() + createObservationViewModels() +
                                createSrvaViewModels() + createPointOfInterestViewModels())
            .sorted { first, second in
                first.sortCriteria > second.sortCriteria
            }
        tableViewController.setClusteredItems(items: clusteredItems)
    }

    private func createHarvestViewModels() -> [MapClusteredItemViewModel] {
        let harvestViewModels = mapDataSource.harvestDataSource
            .getEntities().filter { diaryEntry in
                clusteredItems.harvestIds.contains(.objectId(diaryEntry.objectID))
            }
            .map { diaryEntry in
                MapHarvestViewModel(
                    id: .local(objectId: diaryEntry.objectID),
                    speciesCode: diaryEntry.gameSpeciesCode.int32Value,
                    acceptStatus: .accepted,
                    pointOfTime: diaryEntry.pointOfTime.toLocalDateTime(),
                    description: "Harvest".localized()
                )
            }

        return harvestViewModels
    }

    private func createObservationViewModels() -> [MapClusteredItemViewModel] {
        let observationViewModels: [MapClusteredItemViewModel] = mapDataSource.observationDataSource
            .getEntities().filter { observation in
                if let obserationLocalId = observation.localId {
                    return clusteredItems.observationIds.contains(.commonLocalId(obserationLocalId))
                } else {
                    return false
                }
            }
            .compactMap { observation in
                // ignore observations that don't have localId or species code(should not happen)
                guard let observationLocalId = observation.localId,
                      let speciesCode = observation.species.knownSpeciesCodeOrNull()?.int32Value else {
                    return nil
                }

                return MapObservationViewModel(
                    id: .commonLocal(commonLocalId: observationLocalId),
                    speciesCode: speciesCode,
                    acceptStatus: .accepted,
                    pointOfTime: observation.pointOfTime,
                    description: "Observation".localized()
                )
            }

        return observationViewModels
    }

    private func createSrvaViewModels() -> [MapClusteredItemViewModel] {
        let srvaViewModels: [MapClusteredItemViewModel] = mapDataSource.srvaDataSource
            .getEntities().filter { srva in
                if let srvaLocalId = srva.localId {
                    return clusteredItems.srvaIds.contains(.commonLocalId(srvaLocalId))
                } else {
                    return false
                }
            }
            .compactMap { srva in
                // ignore srvas that don't have localId (should not happen)
                guard let srvaLocalId = srva.localId else {
                    return nil
                }

                return MapSrvaViewModel(
                    id: .commonLocal(commonLocalId: srvaLocalId),
                    species: srva.species,
                    otherSpeciesDescription: srva.otherSpeciesDescription,
                    acceptStatus: .accepted,
                    pointOfTime: srva.pointOfTime,
                    description: "Srva".localized()
                )
            }

        return srvaViewModels
    }

    private func createPointOfInterestViewModels() -> [MapClusteredItemViewModel] {
        let pointOfInterestViewModels: [MapClusteredItemViewModel] = clusteredItems.pointOfInterests
            .compactMap { markerItemId in
                guard case .pointOfInterest(let pointOfInterest) = markerItemId else {
                    return nil
                }

                return MapPointOfInterestViewModel(pointOfInterest: pointOfInterest)
            }

        return pointOfInterestViewModels
    }
}

