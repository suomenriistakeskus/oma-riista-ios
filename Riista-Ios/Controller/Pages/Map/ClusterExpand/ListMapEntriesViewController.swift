import Foundation
import RiistaCommon

typealias ListMapEntriesViewControllerListener = MapHarvestCellClickHandler & MapObservationCellClickHandler &
    MapSrvaCellClickHandler & MapPointOfInterestCellClickHandler

class ListMapEntriesViewController: UIViewController, ProvidesNavigationController, ContainsTableViewForBottomsheet {

    private let clusteredItems: ClusteredMapItems
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

    private let harvestControllerHolder: HarvestControllerHolder
    private let observationsControllerHolder: ObservationControllerHolder
    private let srvaControllerHolder: SrvaControllerHolder

    init(clusteredItems: ClusteredMapItems,
         harvestControllerHolder: HarvestControllerHolder,
         observationsControllerHolder: ObservationControllerHolder,
         srvaControllerHolder: SrvaControllerHolder,
         listener: ListMapEntriesViewControllerListener
    ) {
        self.clusteredItems = clusteredItems
        self.harvestControllerHolder = harvestControllerHolder
        self.observationsControllerHolder = observationsControllerHolder
        self.srvaControllerHolder = srvaControllerHolder
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
        let harvestViewModels = harvestControllerHolder.getObject()
            .fetchedObjects?.filter { diaryEntry in
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

        return harvestViewModels ?? []
    }

    private func createObservationViewModels() -> [MapClusteredItemViewModel] {
        let observationViewModels: [MapClusteredItemViewModel]? = observationsControllerHolder.getObject()
            .fetchedObjects?.filter { observation in
                clusteredItems.observationIds.contains(.objectId(observation.objectID))
            }
            .compactMap { observation in
                // ignore observations that don't specify speciesCode or pointOfTime
                guard let speciesCode = observation.gameSpeciesCode,
                      let pointOfTime = observation.pointOfTime else {
                    return nil
                }

                return MapObservationViewModel(
                    id: .local(objectId: observation.objectID),
                    speciesCode: speciesCode.int32Value,
                    acceptStatus: .accepted,
                    pointOfTime: pointOfTime.toLocalDateTime(),
                    description: "Observation".localized()
                )
            }

        return observationViewModels ?? []
    }

    private func createSrvaViewModels() -> [MapClusteredItemViewModel] {
        let srvaViewModels: [MapClusteredItemViewModel]? = srvaControllerHolder.getObject()
            .fetchedObjects?.filter { srva in
                clusteredItems.srvaIds.contains(.objectId(srva.objectID))
            }
            .compactMap { srva in
                // ignore srvas that don't specify speciesCode or pointOfTime
                guard let speciesCode = srva.gameSpeciesCode,
                      let pointOfTime = srva.pointOfTime else {
                    return nil
                }

                return MapSrvaViewModel(
                    id: .local(objectId: srva.objectID),
                    speciesCode: speciesCode.int32Value,
                    acceptStatus: .accepted,
                    pointOfTime: pointOfTime.toLocalDateTime(),
                    description: "Srva".localized()
                )
            }

        return srvaViewModels ?? []
    }

    private func createPointOfInterestViewModels() -> [MapClusteredItemViewModel] {
        let pointOfInterestViewModels: [MapClusteredItemViewModel]? = clusteredItems.pointOfInterests
            .compactMap { markerItemId in
                guard case .pointOfInterest(let pointOfInterest) = markerItemId else {
                    return nil
                }

                return MapPointOfInterestViewModel(pointOfInterest: pointOfInterest)
            }

        return pointOfInterestViewModels ?? []
    }
}

