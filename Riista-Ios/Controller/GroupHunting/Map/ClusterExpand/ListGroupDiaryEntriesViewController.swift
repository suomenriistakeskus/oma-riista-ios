import Foundation
import RiistaCommon

typealias ListGroupDiaryEntriesViewControllerListener = MapHarvestCellClickHandler & MapObservationCellClickHandler

class ListGroupDiaryEntriesViewController:
    BaseControllerWithViewModel<ListGroupDiaryEntriesViewModel, ListGroupDiaryEntriesController>,
    ProvidesNavigationController, ContainsTableViewForBottomsheet {

    private let huntingGroupTarget: RiistaCommon.HuntingGroupTarget
    private weak var listener: ListGroupDiaryEntriesViewControllerListener?

    private lazy var _controller: RiistaCommon.ListGroupDiaryEntriesController = {
        RiistaCommon.ListGroupDiaryEntriesController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            huntingGroupTarget: huntingGroupTarget
        )
    }()

    override var controller: ListGroupDiaryEntriesController {
        get {
            _controller
        }
    }

    private lazy var tableViewController: MapClusteredItemsTableViewController = {
        let controller = MapClusteredItemsTableViewController()

        controller.harvestClickHandler = listener
        controller.observationClickHandler = listener

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


    init(huntingGroupTarget: RiistaCommon.HuntingGroupTarget,
         harvestIds: [KotlinLong],
         observationIds: [KotlinLong],
         listener: ListGroupDiaryEntriesViewControllerListener
    ) {
        self.huntingGroupTarget = huntingGroupTarget
        self.listener = listener

        super.init(nibName: nil, bundle: nil)

        _controller.harvestIds = harvestIds
        _controller.observationIds = observationIds
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func loadView() {
        super.loadView()

        let labelContainer = UIView()
        view.addSubview(labelContainer)
        labelContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }

        labelContainer.addSeparatorToBottom()

        let label = UILabel()
        label.font = UIFont.appFont(for: .label, fontWeight: .semibold)
        label.text = "MapLocationHarvestsAndObservations".localized()
        label.textColor = UIColor.applicationColor(TextPrimary)
        labelContainer.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppConstants.UI.DefaultHorizontalInset)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(labelContainer.snp.bottom)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    override func onViewModelLoaded(viewModel: ListGroupDiaryEntriesViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        let clusteredItems: [MapClusteredItemViewModel] = viewModel.entries.compactMap { entry in
            switch (entry.type) {
            case .harvest:
                return MapHarvestViewModel(
                    id: .remote(id: entry.remoteId),
                    speciesCode: entry.speciesCode,
                    acceptStatus: entry.acceptStatus,
                    pointOfTime: entry.pointOfTime,
                    description: joinActorNameAndAcceptStatusDescription(
                        actorName: entry.actorName,
                        acceptStatusDescription: entry.acceptStatus.getHarvestDescription()
                    )
                )
            case .observation:
                return MapObservationViewModel(
                    id: .remote(id: entry.remoteId),
                    speciesCode: entry.speciesCode,
                    acceptStatus: entry.acceptStatus,
                    pointOfTime: entry.pointOfTime,
                    description: joinActorNameAndAcceptStatusDescription(
                        actorName: entry.actorName,
                        acceptStatusDescription: entry.acceptStatus.getObservationDescription()
                    )
                )
            default:
                return nil
            }
        }

        tableViewController.setClusteredItems(items: clusteredItems)
    }

    private func joinActorNameAndAcceptStatusDescription(actorName: String?, acceptStatusDescription: String) -> String {
        if let actorName = actorName {
            return "\(actorName), " + acceptStatusDescription.lowercased(with: RiistaSettings.locale())
        } else {
            return acceptStatusDescription
        }
    }
}


fileprivate extension AcceptStatus {
    func getHarvestDescription() -> String {
        let localizationKey: String
        switch self {
        case .proposed:
            localizationKey = "GroupHuntingProposedHarvest"
            break
        case .accepted:
            localizationKey = "GroupHuntingAcceptedHarvest"
            break
        case .rejected:
            localizationKey = "GroupHuntingRejectedHarvest"
        default:
            print("Unexpected acceptStatus \(self) observed! (falling back to normal Harvest)")
            localizationKey = "Harvest"
            break
        }

        return localizationKey.localized()
    }

    func getObservationDescription() -> String {
        let localizationKey: String
        switch self {
        case .proposed:
            localizationKey = "GroupHuntingProposedObservation"
            break
        case .accepted:
            localizationKey = "GroupHuntingAcceptedObservation"
            break
        case .rejected:
            localizationKey = "GroupHuntingRejectedObservation"
        default:
            print("Unexpected acceptStatus \(self) observed! (falling back to normal Observation)")
            localizationKey = "Observation"
            break
        }

        return localizationKey.localized()
    }
}
