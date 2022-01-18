import Foundation
import UIKit
import SnapKit
import RiistaCommon


protocol SelectGroupHuntingDayViewControllerListener: AnyObject {
    func onHuntingDaySelected(huntingDayId: GroupHuntingDayId)
}

class SelectGroupHuntingDayViewController:
    BaseControllerWithViewModel<SelectHuntingDayViewModel, SelectHuntingDayController>,
    ProvidesNavigationController, SelectableHuntingDayCellListener,
    ModifyGroupHuntingDayViewControllerDelegate {

    var huntingGroupTarget: RiistaCommon.IdentifiesHuntingGroup
    var preferredHuntingDayDate: RiistaCommon.LocalDate?

    weak var listener: SelectGroupHuntingDayViewControllerListener?

    private lazy var _controller: RiistaCommon.SelectHuntingDayController = {
        let controller = RiistaCommon.SelectHuntingDayController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            groupTarget: huntingGroupTarget,
            stringProvider: LocalizedStringProvider()
        )
        controller.preferredHuntingDayDate = preferredHuntingDayDate
        return controller
    }()

    override var controller: SelectHuntingDayController {
        get {
            _controller
        }
    }

    private lazy var tableViewController: SelectableHuntingDaysTableViewController = {
        let controller = SelectableHuntingDaysTableViewController(huntingDayListener: self)
        controller.tableView = selectDayView.tableView
        return controller
    }()

    private lazy var selectDayView: SelectGroupHuntingDayView = {
        let view = SelectGroupHuntingDayView()
        view.onCancelButtonClicked = { [weak self] in
            self?.onCancelClicked()
        }
        view.onSelectButtonClicked = { [weak self] in
            self?.onSelectClicked()
        }
        view.onCreateHuntingDayButtonClicked = { [weak self] in
            self?.onCreateHuntingDay(preferredDate: self?.preferredHuntingDayDate)
        }
        return view
    }()

    private lazy var createHuntingDayNavBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "plus"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(onCreateHuntingDayClicked))
        button.isHidden = true
        return button
    }()

    init(huntingGroupTarget: RiistaCommon.IdentifiesHuntingGroup, preferredHuntingDayDate: RiistaCommon.LocalDate?) {
        self.huntingGroupTarget = huntingGroupTarget
        self.preferredHuntingDayDate = preferredHuntingDayDate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func loadView() {
        super.loadView()

        view.addSubview(selectDayView)
        selectDayView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "GroupHuntingHuntingDays".localized()
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
            createHuntingDayNavBarButton
        ]
    }

    @objc func onCreateHuntingDayClicked() {
        onCreateHuntingDay(preferredDate: nil)
    }

    @objc func onRefreshClicked() {
        controllerHolder.loadViewModel(refresh: true)
    }

    func onSelectClicked() {
        guard let selectedHuntingDayId = controller.getLoadedViewModelOrNull()?.selectedHuntingDayId else {
            print("No hunting day selected, cannot notify")
            return
        }

        listener?.onHuntingDaySelected(huntingDayId: selectedHuntingDayId)
        navigationController?.popViewController(animated: true)
    }

    func onCancelClicked() {
        navigationController?.popViewController(animated: true)
    }

    override func onViewModelLoaded(viewModel: SelectHuntingDayViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        createHuntingDayNavBarButton.isHidden = !viewModel.canCreateHuntingDay
        selectDayView.canSelectHuntingDay = viewModel.selectedHuntingDayId != nil

        if (viewModel.huntingDays.count > 0) {
            tableViewController.setHuntingDays(huntingDays: viewModel.huntingDays)
            selectDayView.displayHuntingDays(suggestedHuntingDayDate: viewModel.suggestedHuntingDayDate)
        } else {
            selectDayView.showNoContentText(
                suggestedHuntingDayDate: viewModel.suggestedHuntingDayDate,
                fallbackText: viewModel.noHuntingDaysText,
                canCreateHuntingDay: viewModel.canCreateHuntingDay
            )
        }
    }

    private func formatSuggestedHuntingDayText(date: LocalDate) -> String {
        let format = "GroupHuntingSuggestedHuntingDayForEntry".localized()
        return String(format: format, date.toFoundationDate().formatDateOnly())
    }

    override func onViewModelLoadFailed() {
        super.onViewModelLoadFailed()
    }

    func onRequestSelectHuntingDay(huntingDayId: GroupHuntingDayId) {
        controller.eventDispatcher.dispatchHuntingDaySelected(huntingDayId: huntingDayId)
    }

    func onCreateHuntingDay(preferredDate: RiistaCommon.LocalDate?) {
        let viewController = CreateGroupHuntingDayViewController(
            huntingGroupTarget: huntingGroupTarget,
            preferredDate: preferredDate,
            delegate: self
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    func onHuntingDaysChanged() {
        controllerHolder.shouldRefreshViewModel = true
    }


    // MARK: ModifyGroupHuntingDayViewControllerDelegate

    func onHuntingDaySaved() {
        controllerHolder.shouldRefreshViewModel = true
        navigationController?.popToViewController(self, animated: true)
    }
}
