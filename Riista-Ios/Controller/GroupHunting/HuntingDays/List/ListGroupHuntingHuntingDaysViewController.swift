import Foundation
import UIKit
import SnapKit
import RiistaCommon


class ListGroupHuntingHuntingDaysController:
    BaseControllerWithViewModel<ListHuntingDaysViewModel, ListHuntingDaysController>,
    ProvidesNavigationController, ViewHuntingDayListener,
    ModifyGroupHuntingDayViewControllerDelegate {

    var groupTarget: RiistaCommon.HuntingGroupTarget

    private lazy var _controller: RiistaCommon.ListHuntingDaysController = {
        RiistaCommon.ListHuntingDaysController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            groupTarget: groupTarget,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: ListHuntingDaysController {
        get {
            _controller
        }
    }

    private lazy var dateFilter: DateFilterView = {
        let filter = DateFilterView().withSeparatorAtBottom()
        filter.presentingViewController = self

        filter.onStartDateChanged = { [weak self] startDate in
            self?.controller.eventDispatcher.dispatchFilterStartDateChanged(
                newStartDate: startDate.toLocalDate()
            )
        }
        filter.onEndDateChanged = { [weak self] endDate in
            self?.controller.eventDispatcher.dispatchFilterEndDateChanged(
                newEndDate: endDate.toLocalDate()
            )
        }

        return filter
    }()

    private lazy var tableViewController: HuntingDaysTableViewController = {
        let controller = HuntingDaysTableViewController()
        controller.actionListener = self
        return controller
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 70
        tableView.rowHeight = UITableView.automaticDimension

        tableViewController.tableView = tableView

        return tableView
    }()

    private lazy var noContentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(GreyDark)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var noContentCreateHuntingDayButton: MaterialButton = {
        let button = MaterialButton()
        AppTheme.shared.setupPrimaryButtonTheme(button: button)
        button.setTitle("GroupHuntingAddHuntingDay".localized(), for: .normal)
        button.onClicked = { [weak self] in
            self?.onCreateHuntingDayClicked()
        }
        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight).priority(999)
        }
        button.isHidden = true

        return button
    }()

    private lazy var noContentArea: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .vertical
        stackview.alignment = .fill
        stackview.spacing = 12

        stackview.addArrangedSubview(noContentLabel)
        stackview.addArrangedSubview(noContentCreateHuntingDayButton)
        stackview.isHidden = true
        return stackview
    }()

    private lazy var createHuntingDayNavBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "plus"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(onCreateHuntingDayClicked))
        button.isHidden = true
        return button
    }()

    init(groupTarget: RiistaCommon.HuntingGroupTarget) {
        self.groupTarget = groupTarget
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func loadView() {
        super.loadView()

        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }

        container.addArrangedSubview(dateFilter)

        let tableViewContainer = UIView()
        tableViewContainer.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableViewContainer.addSubview(noContentArea)
        noContentArea.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        container.addArrangedSubview(tableViewContainer)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "GroupHuntingHuntingDays".localized()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.rightBarButtonItems = createNavigationBarItems()
    }

    private func createNavigationBarItems() -> [UIBarButtonItem] {
        [
            UIBarButtonItem(
                image: UIImage(named: "refresh_white"),
                style: .plain,
                target: self,
                action: #selector(onRefreshClicked)
            ),
            createHuntingDayNavBarButton
        ]
    }

    @objc func onCreateHuntingDayClicked() {
        onCreateHuntingDay(preferredDate: nil)
    }

    @objc func onRefreshClicked() {
        controllerHolder.loadViewModel(refresh: true)
    }

    override func onViewModelLoaded(viewModel: ListHuntingDaysViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        createHuntingDayNavBarButton.isHidden = !viewModel.canCreateHuntingDay

        if let huntingDays = viewModel.huntingDays {
            showDateFilter(huntingDays: huntingDays)

            if (viewModel.containsHuntingDaysAfterFiltering) {
                displayHuntingDays(huntingDays: huntingDays)
            } else {
                showNoContentAfterFiltering(canCreateHuntingDay: viewModel.canCreateHuntingDay)
            }
        } else {
            // no hunting days at all -> indicate
            dateFilter.isHidden = true
            showNoContentText(
                text: viewModel.noHuntingDaysText,
                canCreateHuntingDay: viewModel.canCreateHuntingDay
            )
        }
    }

    private func displayHuntingDays(huntingDays: HuntingDays) {
        hideNoContentText()
        tableViewController.setHuntingDays(huntingDays: huntingDays.filteredHuntingDays)
    }

    private func showNoContentAfterFiltering(canCreateHuntingDay: Bool) {
        let noContentTextKey: String
        if (canCreateHuntingDay) {
            noContentTextKey = "GroupHuntingNoHuntingDaysAfterFilteringButCanCreate"
        } else {
            noContentTextKey = "GroupHuntingNoHuntingDaysAfterFiltering"
        }
        showNoContentText(text: noContentTextKey.localized(), canCreateHuntingDay: canCreateHuntingDay)
    }

    private func showDateFilter(huntingDays: HuntingDays) {
        dateFilter.isHidden = false

        dateFilter.minStartDate = huntingDays.minFilterDate.toFoundationDate()
        dateFilter.maxEndDate = huntingDays.maxFilterDate.toFoundationDate()
        dateFilter.startDate = huntingDays.filterStartDate.toFoundationDate()
        dateFilter.endDate = huntingDays.filterEndDate.toFoundationDate()
    }

    private func showNoContentText(text: String?, canCreateHuntingDay: Bool) {
        noContentArea.isHidden = false
        noContentLabel.text = text ?? ""
        noContentCreateHuntingDayButton.isHidden = !canCreateHuntingDay
        tableViewController.setHuntingDays(huntingDays: [])
        tableView.isScrollEnabled = false
    }

    private func hideNoContentText() {
        noContentArea.isHidden = true
        tableView.isScrollEnabled = true
    }

    override func onViewModelLoadFailed() {
        super.onViewModelLoadFailed()
    }

    func onViewHuntingDay(viewModel: HuntingDayViewModel) {
        let huntingDayTarget = GroupHuntingTargetKt.createTargetForHuntingDay(groupTarget, huntingDayId: viewModel.huntingDay.id)
        let viewController = ViewGroupHuntingDayViewController(
            huntingDayTarget: huntingDayTarget,
            actionListener: self
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    func onEditHuntingDay(huntingDayId: GroupHuntingDayId) {
        let huntingDayTarget = GroupHuntingTargetKt.createTargetForHuntingDay(groupTarget, huntingDayId: huntingDayId)

        let viewController = EditGroupHuntingDayViewController(
            huntingDayTarget: huntingDayTarget,
            delegate: self
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    func onCreateHuntingDay(preferredDate: RiistaCommon.LocalDate?) {
        let viewController = CreateGroupHuntingDayViewController(
            huntingGroupTarget: groupTarget,
            preferredDate: preferredDate,
            delegate: self
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    func onHuntingDaysChanged() {
        controllerHolder.shouldRefreshViewModel = true
    }

    func onHarvestOrObservationUpdated() {
        controllerHolder.shouldRefreshViewModel = true
    }


    // MARK: ModifyGroupHuntingDayViewControllerDelegate

    func onHuntingDaySaved() {
        controllerHolder.shouldRefreshViewModel = true
        navigationController?.popToViewController(self, animated: true)
    }
}
