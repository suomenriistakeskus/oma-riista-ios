import Foundation
import UIKit
import SnapKit
import RiistaCommon

protocol ViewHuntingDayListener: HuntingDayActionListener {
    /**
     * Notifies listener that harvest or observation has been updated. Thay may have an effect on
     * e.g. what data is displayed on hunting days list.
     */
    func onHarvestOrObservationUpdated()
}

class ViewGroupHuntingDayViewController:
    BaseControllerWithViewModel<HuntingDayViewModel, ViewGroupHuntingDayController>,
    ProvidesNavigationController,
    ModifyGroupHuntingDayViewControllerDelegate,
    HarvestFieldCellClickHandler, ViewGroupHarvestListener,
    ObservationFieldCellClickHandler, ViewGroupObservationListener,
    CreateHuntingDayCellListener {

    private let huntingDayTarget: RiistaCommon.GroupHuntingDayTarget
    private weak var actionListener: ViewHuntingDayListener?

    private lazy var _controller: RiistaCommon.ViewGroupHuntingDayController = {
        RiistaCommon.ViewGroupHuntingDayController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            huntingDayTarget: huntingDayTarget
        )
    }()

    override var controller: ViewGroupHuntingDayController {
        get {
            _controller
        }
    }

    // ViewGroupHuntingDayController doesn't yet internally produce data fields
    // -> produce them using separate helper
    private lazy var dataFieldSource: ViewHuntingDayDataFields = {
        ViewHuntingDayDataFields(stringProvider: LocalizedStringProvider())
    }()

    private let tableViewController = DataFieldTableViewController<ViewHuntingDayField>()

    private lazy var editHuntingDayButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "edit"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(onEditHuntingDayClicked))
        button.isHidden = true
        return button
    }()

    private lazy var createHuntingDayButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "plus"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(onCreateHuntingDayClicked))
        button.isHidden = true
        return button
    }()

    init(huntingDayTarget: RiistaCommon.GroupHuntingDayTarget,
         actionListener: ViewHuntingDayListener) {
        self.huntingDayTarget = huntingDayTarget
        self.actionListener = actionListener

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func loadView() {
        super.loadView()

        let tableView = TableView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }

        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 70
        tableView.rowHeight = UITableView.automaticDimension

        tableViewController.setTableView(tableView)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.addDefaultCellFactories(
            navigationControllerProvider: self,
            harvestClickHandler: self,
            observationClickHandler: self
        )

        tableViewController.addCellFactory(
            CreateHuntingDayCell.Factory(createHuntingDayCellListener: self)
        )

        title = "GroupHuntingHuntingDay".localized()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navController = navigationController as? RiistaNavigationController {
            navController.setRightBarItems(createNavigationBarItems())
        }
    }

    private func createNavigationBarItems() -> [UIBarButtonItem] {
        [
            UIBarButtonItem(
                image: UIImage(named: "refresh_white"),
                style: .plain,
                target: self,
                action: #selector(onRefreshClicked)
            ),
            editHuntingDayButton,
            createHuntingDayButton
        ]
    }

    @objc func onRefreshClicked() {
        controllerHolder.loadViewModel(refresh: true)
    }

    @objc func onEditHuntingDayClicked() {
        let viewController = EditGroupHuntingDayViewController(
            huntingDayTarget: huntingDayTarget,
            delegate: self
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    func onCreateHuntingDayRequested() {
        startCreateHuntingDay()
    }

    @objc func onCreateHuntingDayClicked() {
        startCreateHuntingDay()
    }

    private func startCreateHuntingDay() {
        // preferred date exists for local days
        let preferredDate = huntingDayTarget.huntingDayId.date

        let viewController = CreateGroupHuntingDayViewController(
            huntingGroupTarget: huntingDayTarget,
            preferredDate: preferredDate,
            delegate: self
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    override func onViewModelLoaded(viewModel: HuntingDayViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        dataFieldSource.updateFields(huntingDayViewModel: viewModel)
        tableViewController.setDataFields(dataFields: dataFieldSource.huntingDayFields)

        editHuntingDayButton.isHidden = !viewModel.canEditHuntingDay
        createHuntingDayButton.isHidden = !viewModel.canCreateHuntingDay
    }

    func onHarvestClicked(harvestId: Int64, acceptStatus: AcceptStatus) {
        let viewController = ViewGroupHuntingHarvestViewController(
            harvestTarget: GroupHuntingTargetKt.createTargetForHarvest(huntingDayTarget, harvestId: harvestId),
            acceptStatus: acceptStatus,
            listener: self
        )
        navigationController?.pushViewController(viewController, animated: true)
    }

    func onHarvestUpdated() {
        controllerHolder.shouldRefreshViewModel = true
        actionListener?.onHarvestOrObservationUpdated()
    }

    func onObservationClicked(observationId: Int64, acceptStatus: AcceptStatus) {
        let viewController = ViewGroupHuntingObservationViewController(
            observationTarget: GroupHuntingTargetKt.createTargetForObservation(huntingDayTarget, observationId: observationId),
            acceptStatus: acceptStatus,
            listener: self
        )
        navigationController?.pushViewController(viewController, animated: true)
    }

    func onObservationUpdated() {
        controllerHolder.shouldRefreshViewModel = true
        actionListener?.onHarvestOrObservationUpdated()
    }


    // MARK: ModifyGroupHuntingDayViewControllerDelegate

    func onHuntingDaySaved() {
        actionListener?.onHuntingDaysChanged()

        controllerHolder.shouldRefreshViewModel = true
        navigationController?.popToViewController(self, animated: true)
    }
}
