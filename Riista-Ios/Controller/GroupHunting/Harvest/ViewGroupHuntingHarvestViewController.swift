import Foundation
import UIKit
import DropDown
import MaterialComponents
import SnapKit
import RiistaCommon

protocol ViewGroupHarvestListener: AnyObject {
    func onHarvestUpdated()
}

fileprivate let REJECT_HARVEST: Int = 1

class ViewGroupHuntingHarvestViewController:
    BaseControllerWithViewModel<ViewGroupHarvestViewModel, ViewGroupHarvestController>,
    ProvidesNavigationController, EditGroupHarvestListener,
    CreateGroupHuntingObservationViewControllerListener,
    ViewGroupObservationListener,
    MapExternalIdProvider {

    private let harvestTarget: RiistaCommon.GroupHuntingHarvestTarget
    private var acceptStatus: RiistaCommon.AcceptStatus
    private weak var listener: ViewGroupHarvestListener?

    /**
     * The external id of the hunting group area on the map.
     */
    private var groupAreaMapExternalId: String?

    /**
     * Should a dialog be presented asking whether an observation has been created for this harvest?
     *
     * This flag should probably be raised when a harvest has been created / approved.
     */
    var askToCreateObservationBasedOnHarvest: Bool = false

    private lazy var _controller: RiistaCommon.ViewGroupHarvestController = {
        RiistaCommon.ViewGroupHarvestController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            harvestTarget: harvestTarget,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: ViewGroupHarvestController {
        get {
            _controller
        }
    }

    private let tableViewController = DataFieldTableViewController<GroupHarvestField>()

    private lazy var continueToApproveArea: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.applicationColor(ViewBackground)
        view.addSubview(continueToApproveButton)
        continueToApproveButton.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight).priority(999)
            make.leading.trailing.equalToSuperview().inset(AppConstants.UI.DefaultHorizontalInset)
            make.top.bottom.trailing.equalToSuperview().inset(AppConstants.UI.DefaultVerticalInset).priority(999)
        }

        let separator = SeparatorView(orientation: .horizontal)
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }

        view.isHidden = true
        return view
    }()

    private lazy var continueToApproveButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        btn.setTitle("GroupHuntingContinueToApprove".localized(), for: .normal)
        btn.onClicked = { [weak self] in
            self?.continueToApprove()
        }
        return btn
    }()

    private lazy var editNavBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(named: "edit")?.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(onEditButtonClicked)
        )
        button.isHidden = true // by default, will be displayed later if allowed
        return button
    }()

    private lazy var moreMenuButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(named: "more_menu"),
            style: .plain,
            target: self,
            action: #selector(onMoreMenuItemClicked)
        )
        button.isHidden = true // by default, will be displayed based on moreMenuItems
        return button
    }()

    private lazy var moreMenuItems: DropdownItemProvider = {
        let provider = DropdownItemProvider()
        provider.addItem(DropdownItem(
            id: REJECT_HARVEST,
            title: "RejectHarvest".localized(),
            hidden: true,
            onClicked: { [weak self] in
                self?.onRejectHarvestClicked()
            }
        ))
        provider.onItemsChanged = { [weak self] in
            let displayMoreMenu = (self?.moreMenuItems.visibleItems.count ?? 0) > 0
            self?.moreMenuButton.isHidden = !displayMoreMenu
        }
        return provider
    }()

    init(harvestTarget: GroupHuntingHarvestTarget,
         acceptStatus: RiistaCommon.AcceptStatus,
         listener: ViewGroupHarvestListener) {
        self.harvestTarget = harvestTarget
        self.acceptStatus = acceptStatus
        self.listener = listener

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

        let tableView = TableView()
        container.addArrangedSubview(tableView)
        // will be isHidden status will be updated later if can be approved
        continueToApproveButton.isHidden = (acceptStatus == .accepted)
        container.addArrangedSubview(continueToApproveArea)

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
            mapExternalIdProvider: self
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        title = getViewTitle()
        navigationItem.rightBarButtonItems = [moreMenuButton, editNavBarButton]
    }

    @objc func onEditButtonClicked() {
        let editController = EditGroupHuntingHarvestViewController(
            harvestTarget: harvestTarget,
            mode: .edit,
            listener: self
        )
        navigationController?.pushViewController(editController, animated: true)
    }

    @objc func onMoreMenuItemClicked() {
        let dropDown = DropDown()
        dropDown.anchorView = moreMenuButton
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y: moreMenuButton.plainView.bounds.height)
        dropDown.setDataSource(using: moreMenuItems)
        dropDown.selectionAction = { [weak self] (index: Int, _: String) in
            self?.moreMenuItems.onItemSelected(index: index)
        }

        dropDown.show()
    }

    private func onRejectHarvestClicked() {
        let alertController = MDCAlertController(
            title: "AreYouSure".localized(),
            message: "RejectHarvestQuestion".localized()
        )
        alertController.addAction(MDCAlertAction(title: "Yes".localized(), handler: { [weak self] _ in
            self?.rejectHarvest()
        }))
        alertController.addAction(MDCAlertAction(title: "Cancel".localized(), handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    private func rejectHarvest() {
        let loadingIndicator = LoadIndicatorViewController().showIn(parentViewController: self)
        editNavBarButton.isEnabled = false

        controller.rejectHarvest { [weak self] response, error in
            guard let self = self else { return }

            loadingIndicator.hide()
            self.editNavBarButton.isEnabled = true

            if response is GroupHuntingHarvestOperationResponse.Success {
                if let listener = self.listener {
                    listener.onHarvestUpdated()
                }

                self.navigationController?.popViewController(animated: true)
            } else {
                let dialog = AlertDialogBuilder.createError(message: "NetworkOperationFailed".localized())
                self.navigationController?.present(dialog, animated: true, completion: nil)
            }
        }
    }

    private func updateApproveVisibility(canApprove: Bool) {
        UIView.animate(withDuration: AppConstants.Animations.durationShort) {
            self.continueToApproveArea.isHidden = !canApprove
        }
    }

    private func updateEditButtonVisibility(canEdit: Bool) {
        editNavBarButton.isHidden = !canEdit
    }

    private func updateRejectButtonVisibility(canReject: Bool) {
        moreMenuItems.setItemVisibility(id: REJECT_HARVEST, visible: canReject)
    }

    private func continueToApprove() {
        let approveController = EditGroupHuntingHarvestViewController(
            harvestTarget: harvestTarget,
            mode: .approve,
            listener: self
        )
        navigationController?.pushViewController(approveController, animated: true)
    }

    override func onViewModelLoaded(viewModel: ViewGroupHarvestViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        groupAreaMapExternalId = viewModel.huntingGroupArea?.externalId

        updateApproveVisibility(canApprove: viewModel.canApproveHarvest)
        updateEditButtonVisibility(canEdit: viewModel.canEditHarvest)
        updateRejectButtonVisibility(canReject: viewModel.canRejectHarvest)
        tableViewController.setDataFields(dataFields: viewModel.fields)

        askToCreateObservationBasedOnHarvestIfNeeded()
    }

    override func onViewModelLoadFailed() {
        super.onViewModelLoadFailed()
    }

    private func getViewTitle() -> String {
        let localizationKey: String
        switch acceptStatus {
        case .proposed:
            localizationKey = "GroupHuntingProposedHarvest"
            break
        case .accepted:
            localizationKey = "GroupHuntingAcceptedHarvest"
            break
        case .rejected:
            localizationKey = "GroupHuntingRejectedHarvest"
            break
        default:
            print("Unexpected acceptStatus \(acceptStatus) observed! (falling back to normal Harvest)")
            localizationKey = "Harvest"
            break
        }

        return localizationKey.localized()
    }

    private func askToCreateObservationBasedOnHarvestIfNeeded() {
        if (!askToCreateObservationBasedOnHarvest) {
            return
        }

        askToCreateObservationBasedOnHarvest = false

        let messageController = MDCAlertController(title: "GroupHuntingCreateObservationFromHarvestTitle".localized(),
                                                   message: "GroupHuntingCreateObservationFromHarvestMessage".localized())
        let noAction = MDCAlertAction(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "No"),
            handler: { [weak self] _ in
                self?.createObservationBasedOnHarvest()
            }
        )
        let yesAction = MDCAlertAction(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "Yes"),
            handler: { _ in
                // nop
                //dismiss(animated: true, completion: nil)
            }
        )

        messageController.addAction(noAction)
        messageController.addAction(yesAction)

        navigationController?.present(messageController, animated: true, completion: nil)
    }

    private func createObservationBasedOnHarvest() {
        let viewController = CreateGroupHuntingObservationViewController(
            huntingGroupTarget: harvestTarget,
            sourceHarvestTarget: harvestTarget,
            listener: self
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

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

    func onObservationUpdated() {
        // nop
    }


    // MARK: EditGroupHarvestListener

    func onHarvestApproved(canCreateObservation: Bool) {
        acceptStatus = .accepted
        askToCreateObservationBasedOnHarvest = canCreateObservation

        onHarvestUpdated()
    }

    func onHarvestUpdated() {
        if let listener = self.listener {
            listener.onHarvestUpdated()
        }

        controllerHolder.shouldRefreshViewModel = true
        navigationController?.popToViewController(self, animated: true)
    }

    // MARK: MapExternalIdProvider

    func getMapExternalId() -> String? {
        groupAreaMapExternalId
    }
}
