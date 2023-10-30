import Foundation
import MaterialComponents
import SnapKit
import RiistaCommon
import Async


class HuntingControlLandingPageViewController :
    BaseControllerWithViewModel<SelectHuntingControlEventViewModel, SelectHuntingControlEventController>,
    SelectSingleStringViewControllerDelegate,
    ViewHuntingControlEventListener,
    CreateHuntingControlEventViewControllerListener {

    private(set) var _controller = RiistaCommon.SelectHuntingControlEventController(
        huntingControlContext: RiistaSDK.shared.huntingControlContext,
        languageProvider: CurrentLanguageProvider(),
        stringProvider: LocalizedStringProvider()
    )

    override var controller: SelectHuntingControlEventController {
        get {
            _controller
        }
    }

    private lazy var tableViewController: HuntingControlEventsTableViewController = {
        let tableViewController = HuntingControlEventsTableViewController()
        tableViewController.viewEventListener = self
        return tableViewController
    }()

    private(set) lazy var tableView: TableView = {
        let tableView = TableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension

        tableViewController.tableView = tableView

        tableView.tableHeaderView = headerContainer
        headerContainer.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }

        return tableView
    }()

    private(set) lazy var headerContainer: UIStackView = {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill
        container.spacing = 8
        container.isLayoutMarginsRelativeArrangement = true
        container.layoutMargins = UIEdgeInsets(top: AppConstants.UI.DefaultVerticalInset,
                                               left: AppConstants.UI.DefaultHorizontalInset,
                                               bottom: 0,
                                               right: AppConstants.UI.DefaultHorizontalInset)

        container.translatesAutoresizingMaskIntoConstraints = false

        container.addView(hunterInfoButton)
        container.addView(addEventButton)
        container.addView(selectRhyView)

        let eventsTitle = UILabel().configure(fontSize: .small, fontWeight: .bold)
        eventsTitle.text = "HuntingControlMyEvents".localized()
        container.addView(eventsTitle, spaceBefore: 12)
        container.addSeparator()

        return container
    }()

    private(set) lazy var hunterInfoButton: MaterialCardButton = {
        let button = MaterialCardButton()
        button.setTitle("HuntingControlCheckHunter".localized())
        button.setImage(named: "calendar")
        button.button.iconSize = CGSize(width: 40, height: 40)
        button.button.imageView?.contentMode = .scaleAspectFit
        button.setClickTarget(self, action: #selector(onHunterInfoClicked))

        button.snp.makeConstraints { make in
            make.height.equalTo(button.snp.width).multipliedBy(0.33)
        }
        return button
    }()

    private(set) lazy var addEventButton: MaterialCardButton = {
        let button = MaterialCardButton()
        button.setTitle("HuntingControlAddEvent".localized())
        button.setImage(named: "calendar_plus")
        button.button.iconSize = CGSize(width: 40, height: 40)
        button.button.imageView?.contentMode = .scaleAspectFit
        button.setClickTarget(self, action: #selector(onAddEventClicked))

        button.snp.makeConstraints { make in
            make.height.equalTo(button.snp.width).multipliedBy(0.33)
        }
        return button
    }()

    private(set) lazy var selectRhyView: SelectStringView = {
        let view = SelectStringView()
        view.label.text = "HuntintControlRhy".localized()
        view.onClicked = { [weak self] in
            self?.launchRhySelection()
        }
        view.isHidden = true
        return view
    }()

    private lazy var synchronizeEventsButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "refresh_white"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(onRefreshHuntingEvents))
        return button
    }()

    override func loadView() {
        super.loadView()

        view.addSubview(self.tableView)

        tableView.snp.makeConstraints { make in
            // let tableview take all space. The cells need to therefore respect preferred layoutmargins
            make.leading.trailing.equalTo(view)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        title = "HuntingControlLandingPageTitle".localized()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.rightBarButtonItems = [synchronizeEventsButton]
    }

    override func onViewWillAppear() {
        controllerHolder.bindToViewModelLoadStatus()

        // override default viewmodel loading in order to always load contents again from the database.
        // -> "modified" indicators are displayed correctly
        controllerHolder.loadViewModel(refresh: controllerHolder.shouldRefreshViewModel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(CGSize(width: tableView.frame.width, height: 10000),
                                                            withHorizontalFittingPriority: .required,
                                                            verticalFittingPriority: .fittingSizeLevel).height
            var headerFrame = headerView.frame

            if (height != headerFrame.height) {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }

    @objc private func onRefreshHuntingEvents() {
        tableView.showLoading()
        synchronizeEventsButton.isEnabled = false

        controller.loadViewModel(
            refresh: true,
            completionHandler: handleOnMainThread { [weak self] _ in
                guard let self = self else { return }

                self.tableView.hideLoading()
                self.synchronizeEventsButton.isEnabled = true
            }
        )
    }

    private func onHeaderContentsChanged() {
        // header size changed, re-layout view so that header size gets re-set upon viewDidLayoutSubviews()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }

    @objc private func onAddEventClicked() {
        guard let selectedRhy = controller.getLoadedViewModelOrNull()?.selectedRhy else {
            print("Cannot create hunting control event, rhy not selected")
            return
        }

        let viewController = CreateHuntingControlEventViewController(
            huntingControlRhyTarget: HuntingControlRhyTarget(rhyId: selectedRhy.id),
            listener: self
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc private func onHunterInfoClicked() {
        let viewController = HunterInfoViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func updateSelectRhyView(showRhy: Bool, selectedRhy: StringWithId?) {
        if (selectRhyView.isHidden != !showRhy) {
            UIView.animate(withDuration: AppConstants.Animations.durationShort) {
                self.selectRhyView.isHidden = !showRhy
                self.onHeaderContentsChanged()
            }
        }

        selectRhyView.valueLabel.text = selectedRhy?.string ?? ""
    }

    private func launchRhySelection() {
        guard let viewModel = controller.getLoadedViewModelOrNull() else {
            print("No viewmodel, cannot select RHY")
            return
        }

        let viewController = SelectSingleStringViewController()
        viewController.delegate = self
        viewController.title = selectRhyView.label.text
        viewController.setValues(values: viewModel.rhys)

        navigationController?.pushViewController(viewController, animated: true)
    }

    override func onViewModelLoaded(viewModel: SelectHuntingControlEventViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        let events = viewModel.events ?? []
        tableViewController.setHuntingControlEvents(events: events)
        if (events.isEmpty) {
            let noEventsTextKey = viewModel.selectedRhy == nil ?
                "HuntingControlSelectRhyToDisplayEvents" :
                "HuntingControlNoEvents"
            tableViewController.showNoHuntingControlEventsText(noEventsTextKey.localized())
        }

        addEventButton.setEnabled(enabled: viewModel.selectedRhy != nil)
        updateSelectRhyView(showRhy: viewModel.showRhy, selectedRhy: viewModel.selectedRhy)
    }

    override func onViewModelLoadFailed() {
        super.onViewModelLoadFailed()

        tableViewController.setHuntingControlEvents(events: [])
        tableViewController.showNoHuntingControlEventsText("HuntingControlNoEvents".localized())

        addEventButton.setEnabled(enabled: false)
        updateSelectRhyView(showRhy: false, selectedRhy: nil)
    }


    // MARK: - SelectSingleStringViewControllerDelegate

    func onStringSelected(string: SelectSingleStringViewController.SelectableString) {
        controller.eventDispatcher.dispatchRhySelected(id: string.id)
    }


    // MARK: - ViewHuntingControlEventListener

    func onViewHuntingControlEvent(eventId: Int64) {
        guard let selectedRhyId = controller.getLoadedViewModelOrNull()?.selectedRhy?.id else {
            print("No selected rhy, cannot display hunting control event")
            return
        }

        let eventTarget = HuntingControlEventTarget(rhyId: selectedRhyId, eventId: eventId)
        let viewEventController = ViewHuntingControlEventViewController(huntingControlEventTarget: eventTarget)
        navigationController?.pushViewController(viewEventController, animated: true)
    }


    // MARK: - CreateHuntingControlEventViewControllerListener

    func onHuntingControlEventCreated(eventTarget: HuntingControlEventTarget) {
        // for some reason refresh causes events to be not displayed
        // figure out the reason in common lib!
        // controllerHolder.shouldRefreshViewModel = true

        let viewEventController = ViewHuntingControlEventViewController(huntingControlEventTarget: eventTarget)

        navigationController?.replaceViewControllers(parentViewController: self,
                                                     childViewController: viewEventController,
                                                     animated: true)
    }
}
