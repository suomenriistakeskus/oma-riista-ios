import Foundation
import UIKit
import MaterialComponents
import SnapKit
import RiistaCommon


class GroupHuntingLandingPageViewController
        : BaseControllerWithViewModel<SelectHuntingGroupViewModel, SelectHuntingGroupController>
        , ProvidesNavigationController
        , CreateGroupHuntingHarvestViewControllerListener, ViewGroupHarvestListener
        , CreateGroupHuntingObservationViewControllerListener, ViewGroupObservationListener {

    private(set) var _controller = RiistaCommon.SelectHuntingGroupController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            stringProvider: LocalizedStringProvider(),
            languageProvider: CurrentLanguageProvider(),
            speciesResolver: SpeciesInformationResolver()
    )

    override var controller: SelectHuntingGroupController {
        get {
            _controller
        }
    }

    /**
     * Should the hunting group data be refreshed next time? Allows updating e.g. proposed entries count.
     */
    private var shouldRefreshGroupDataNextTime: Bool = false

    private let tableViewController = DataFieldTableViewController<SelectHuntingGroupField>()

    private lazy var huntingDaysButton: MaterialCardButton = {
        let button = MaterialCardButton()
        button.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "GroupHuntingHuntingDays"))
        button.setImage(named: "calendar")
        button.setClickTarget(self, action: #selector(onHuntingDaysClicked))
        return button
    }()

    private lazy var mapButton: MaterialCardButton = {
        let button = MaterialCardButton()
        button.setTitle("GroupHuntingEntriesOnMap".localized())
        button.setImage(named: "map_pin")
        button.setClickTarget(self, action: #selector(onMapClicked))
        return button
    }()

    private lazy var createHarvestButton: MaterialCardButton = {
        let button = MaterialCardButton()
        button.setTitle("GroupHuntingNewHarvest".localized())
        button.setImage(named: "harvest")
        button.setClickTarget(self, action: #selector(onNewHarvestClicked))
        return button
    }()

    private lazy var createObservationButton: MaterialCardButton = {
        let button = MaterialCardButton()
        button.setTitle("GroupHuntingNewObservation".localized())
        button.setImage(named: "observation")
        button.setClickTarget(self, action: #selector(onNewObservationClicked))
        return button
    }()

    private lazy var groupHuntingInfoButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(named: "info"),
            style: .plain,
            target: self,
            action: #selector(onGroupHuntingIntroButtonClicked)
        )
        button.isHidden = true
        return button
    }()

    override func loadView() {
        super.loadView()

        let tableView = UITableView()
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            // let tableview take all space. The cells need to therefore respect preferred layoutmargins
            make.leading.trailing.equalTo(view)
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
            stringWithIdEventDispatcher: controller.eventDispatcher
        )

        title = "GroupHuntingLandingPageTitle".localized()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.rightBarButtonItems = createNavigationBarItems()

        updateGroupHuntingInfoButtonVisibility()

        showGroupHuntingIntroMessage(
            onlyShowIfNotShownPreviously: true, // don't allow showing it second time automatically!
            incrementAutomaticDisplayCount: true // trying to display automatically -> increment display count
        )
    }

    private func createNavigationBarItems() -> [UIBarButtonItem] {
        [
            UIBarButtonItem(
                image: UIImage(named: "refresh_white"),
                style: .plain,
                target: self,
                action: #selector(onRefreshClicked)
            ),
            groupHuntingInfoButton
        ]
    }

    private func updateGroupHuntingInfoButtonVisibility() {
        if (getGroupHuntingIntroMessage() != nil) {
            groupHuntingInfoButton.isHidden = false
        } else {
            groupHuntingInfoButton.isHidden = true
        }
    }

    @objc func onRefreshClicked() {
        shouldRefreshGroupDataNextTime = true
        controllerHolder.loadViewModel(refresh: true)
    }

    @objc func onGroupHuntingIntroButtonClicked() {
        showGroupHuntingIntroMessage(onlyShowIfNotShownPreviously: false, incrementAutomaticDisplayCount: false)
    }

    private func showGroupHuntingIntroMessage(
        onlyShowIfNotShownPreviously: Bool,
        incrementAutomaticDisplayCount: Bool
    ) {
        guard let introMessage = getGroupHuntingIntroMessage() else {
            return
        }

        let messageHandler = RiistaSDK.shared.groupHuntingIntroMessageHandler()

        if (onlyShowIfNotShownPreviously) {
            let displayCount = messageHandler.getMessageAutomaticDisplayCount(messageId: introMessage.id)
            if (displayCount != 0) {
                print("Message shown previously, not displaying it now!")
                return
            }
        }

        if (incrementAutomaticDisplayCount) {
            messageHandler.incrementMessageAutomaticDisplayCount(messageId: introMessage.id)
        }

        guard let language = RiistaSettings.language() else {
            CrashlyticsHelper.log(msg: "Language must be known before attempting to display intro message")
            return
        }

        let title = introMessage.localizedTitle(languageCode: language)
        let message = introMessage.localizedMessage(languageCode: language)
        // either title or message is required
        if (title == nil && message == nil) {
            CrashlyticsHelper.log(msg: "Not showing intro message with no title or message")
            return
        }

        let messageController = MDCAlertController(title: title, message: message)
        let okAction = MDCAlertAction(title: "Ok".localized(),
                                      handler: { _ in
            // nop
        })
        messageController.addAction(okAction)

        present(messageController, animated: true, completion: nil)
    }

    private func getGroupHuntingIntroMessage() -> Message? {
        RiistaSDK.shared.groupHuntingIntroMessageHandler().getMessage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let tableView = tableViewController.tableView {
            if (tableView.tableFooterView == nil) {
                tableView.tableFooterView = createButtonsFooter(width: tableView.frame.width, edgeInsets: tableView.layoutMargins)
                tableView.layoutIfNeeded()
            }
        }
    }

    private func createButtonsFooter(width: CGFloat, edgeInsets: UIEdgeInsets) -> UIView {
        let spacing: CGFloat = 8

        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: width))
        containerView.layoutMargins = edgeInsets

        let buttonsStackView = UIStackView()
        containerView.addSubview(buttonsStackView)
        buttonsStackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(containerView.layoutMarginsGuide)
            make.top.equalToSuperview()
            make.height.equalTo(buttonsStackView.snp.width)
        }

        buttonsStackView.axis = .vertical
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.alignment = .fill
        buttonsStackView.spacing = spacing

        let topButtons = UIStackView().apply { topButtons in
            topButtons.axis = .horizontal
            topButtons.distribution = .fillEqually
            topButtons.alignment = .fill
            topButtons.spacing = spacing

            topButtons.addArrangedSubview(huntingDaysButton)
            topButtons.addArrangedSubview(mapButton)
        }
        buttonsStackView.addArrangedSubview(topButtons)

        let bottomButtons = UIStackView().apply { bottomButtons in
            bottomButtons.axis = .horizontal
            bottomButtons.distribution = .fillEqually
            bottomButtons.alignment = .fill
            bottomButtons.spacing = spacing

            bottomButtons.addArrangedSubview(createHarvestButton)
            bottomButtons.addArrangedSubview(createObservationButton)
        }
        buttonsStackView.addArrangedSubview(bottomButtons)

        return containerView
    }

    override func onViewModelLoaded(viewModel: SelectHuntingGroupViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)
        tableViewController.setDataFields(dataFields: viewModel.fields)

        setButtonsEnabledStatus(
            huntingGroupSelected: viewModel.huntingGroupSelected,
            canCreateHarvest: viewModel.canCreateHarvest,
            canCreateObservation: viewModel.canCreateObservation,
            speciesCode: viewModel.selectedSpecies
        )
        updateProposedEntriesCount(viewModel: viewModel)

        controller.fetchHuntingGroupDataIfNeeded(refresh: shouldRefreshGroupDataNextTime) { [weak self] _, _ in
            self?.shouldRefreshGroupDataNextTime = false
        }
    }

    override func onViewModelLoadFailed() {
        super.onViewModelLoadFailed()

        setButtonsEnabledStatus(huntingGroupSelected: false,
                                canCreateHarvest: false,
                                canCreateObservation: false,
                                speciesCode: nil)
        updateProposedEntriesCount(viewModel: nil)
    }

    private func setButtonsEnabledStatus(huntingGroupSelected: Bool,
                                         canCreateHarvest: Bool,
                                         canCreateObservation: Bool,
                                         speciesCode: KotlinInt?) {
        huntingDaysButton.setEnabled(enabled: huntingGroupSelected)
        mapButton.setEnabled(enabled: huntingGroupSelected)

        createHarvestButton.setEnabled(enabled: canCreateHarvest)
        createObservationButton.setEnabled(enabled: canCreateObservation)

        if let speciesCode = speciesCode, SpeciesCodeKt.isDeer(speciesCode.int32Value) {
            createObservationButton.isHidden = true
        } else {
            createObservationButton.isHidden = false
        }
    }

    private func updateProposedEntriesCount(viewModel: SelectHuntingGroupViewModel?) {
        guard let viewModel = viewModel else {
            mapButton.badge.text = nil
            return
        }

        if (viewModel.huntingGroupSelected && viewModel.proposedEventsCount > 0) {
            mapButton.badge.text = "\(viewModel.proposedEventsCount)"
        } else {
            mapButton.badge.text = nil
        }
    }

    @objc func onHuntingDaysClicked() {
        guard let groupTarget = controller.getLoadedViewModelOrNull()?.selectedHuntingGroupTarget else {
            print("No target for group, cannot display!")
            return
        }

        // the proposed entries can be accepted via hunting days -> refresh group data when returning
        shouldRefreshGroupDataNextTime = true

        let viewController = ListGroupHuntingHuntingDaysController(groupTarget: groupTarget)
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc func onMapClicked() {
        guard let huntingGroupTarget = controller.getLoadedViewModelOrNull()?.selectedHuntingGroupTarget else {
            print("No target for group, cannot display!")
            return
        }

        // the proposed entries can be accepted on the map -> refresh group data when returning
        shouldRefreshGroupDataNextTime = true

        let mapController = GroupHuntingMapViewController(huntingGroupTarget: huntingGroupTarget)
        navigationController?.pushViewController(mapController, animated: true)
    }

    @objc func onNewHarvestClicked() {
        guard let groupTarget = controller.getLoadedViewModelOrNull()?.selectedHuntingGroupTarget else {
            print("No target for group, cannot display!")
            return
        }

        let viewController = CreateGroupHuntingHarvestViewController(
            huntingGroupTarget: groupTarget, listener: self
        )
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc func onNewObservationClicked() {
        guard let groupTarget = controller.getLoadedViewModelOrNull()?.selectedHuntingGroupTarget else {
            print("No target for group, cannot display!")
            return
        }

        let viewController = CreateGroupHuntingObservationViewController(
            huntingGroupTarget: groupTarget,
            sourceHarvestTarget: nil,
            listener: self
        )
        navigationController?.pushViewController(viewController, animated: true)
    }


    // MARK: CreateGroupHuntingHarvestViewControllerListener

    func onHarvestCreated(harvestTarget: GroupHuntingHarvestTarget, canCreateObservation: Bool) {
        let viewHarvestController = ViewGroupHuntingHarvestViewController(
            harvestTarget: harvestTarget,
            acceptStatus: .accepted,
            listener: self
        )

        viewHarvestController.askToCreateObservationBasedOnHarvest = canCreateObservation

        navigationController?.replaceViewControllers(parentViewController: self,
                                                     childViewController: viewHarvestController,
                                                     animated: true)
    }


    // MARK: ViewGroupHarvestListener

    func onHarvestUpdated() {
        controllerHolder.shouldRefreshViewModel = true
        navigationController?.popToViewController(self, animated: true)
    }


    // MARK: CreateGroupHuntingObservationViewControllerListener

    func onObservationCreated(observationTarget: GroupHuntingObservationTarget) {
        let viewObservationController = ViewGroupHuntingObservationViewController(
            observationTarget: observationTarget,
            acceptStatus: .accepted,
            listener: self
        )

        navigationController?.replaceViewControllers(parentViewController: self,
                                                     childViewController: viewObservationController,
                                                     animated: true)
    }


    // MARK: ViewGroupObservationListener

    func onObservationUpdated() {
        controllerHolder.shouldRefreshViewModel = true
        navigationController?.popToViewController(self, animated: true)
    }
}
