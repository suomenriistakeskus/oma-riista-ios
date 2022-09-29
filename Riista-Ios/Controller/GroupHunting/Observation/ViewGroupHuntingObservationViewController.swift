import Foundation
import UIKit
import DropDown
import MaterialComponents
import SnapKit
import RiistaCommon

protocol ViewGroupObservationListener: AnyObject {
    func onObservationUpdated()
}

fileprivate let REJECT_OBSERVATION: Int = 1


class ViewGroupHuntingObservationViewController:
    BaseControllerWithViewModel<ViewGroupObservationViewModel, ViewGroupObservationController>,
    ProvidesNavigationController, EditGroupObservationListener,
    MapExternalIdProvider {

    var observationTarget: RiistaCommon.GroupHuntingObservationTarget
    var acceptStatus: RiistaCommon.AcceptStatus
    private weak var listener: ViewGroupObservationListener?

    /**
     * The external id of the hunting group area on the map.
     */
    private var groupAreaMapExternalId: String?

    private lazy var _controller: RiistaCommon.ViewGroupObservationController = {
        RiistaCommon.ViewGroupObservationController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            observationTarget: observationTarget,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: ViewGroupObservationController {
        get {
            _controller
        }
    }

    private let tableViewController = DataFieldTableViewController<GroupObservationField>()

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
            id: REJECT_OBSERVATION,
            title: "RejectObservation".localized(),
            hidden: true,
            onClicked: { [weak self] in
                self?.onRejectObservationClicked()
            }
        ))
        provider.onItemsChanged = { [weak self] in
            let displayMoreMenu = (self?.moreMenuItems.visibleItems.count ?? 0) > 0
            self?.moreMenuButton.isHidden = !displayMoreMenu
        }
        return provider
    }()

    init(observationTarget: GroupHuntingObservationTarget,
         acceptStatus: RiistaCommon.AcceptStatus,
         listener: ViewGroupObservationListener) {
        self.observationTarget = observationTarget
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
        let editController = EditGroupHuntingObservationViewController(
            observationTarget: observationTarget,
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

    private func onRejectObservationClicked() {
        let alertController = MDCAlertController(
            title: "AreYouSure".localized(),
            message: "RejectObservationQuestion".localized()
        )
        alertController.addAction(MDCAlertAction(title: "Yes".localized(), handler: { [weak self] _ in
            self?.rejectObservation()
        }))
        alertController.addAction(MDCAlertAction(title: "Cancel".localized(), handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    private func rejectObservation() {
        let loadingIndicator = LoadIndicatorViewController().showIn(parentViewController: self)
        editNavBarButton.isEnabled = false

        controller.rejectObservation { [weak self] response, error in
            guard let self = self else { return }

            loadingIndicator.hide()
            self.editNavBarButton.isEnabled = true

            if response is GroupHuntingObservationOperationResponse.Success {
                if let listener = self.listener {
                    listener.onObservationUpdated()
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
        moreMenuItems.setItemVisibility(id: REJECT_OBSERVATION, visible: canReject)
    }

    private func continueToApprove() {
        let approveController = EditGroupHuntingObservationViewController(
            observationTarget: observationTarget,
            mode: .approve,
            listener: self
        )
        navigationController?.pushViewController(approveController, animated: true)
    }

    override func onViewModelLoaded(viewModel: ViewGroupObservationViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        groupAreaMapExternalId = viewModel.huntingGroupArea?.externalId

        updateApproveVisibility(canApprove: viewModel.canApproveObservation)
        updateEditButtonVisibility(canEdit: viewModel.canEditObservation)
        updateRejectButtonVisibility(canReject: viewModel.canRejectObservation)
        tableViewController.setDataFields(dataFields: viewModel.fields)
    }

    override func onViewModelLoadFailed() {
        super.onViewModelLoadFailed()
    }

    private func getViewTitle() -> String {
        let localizationKey: String
        switch acceptStatus {
        case .proposed:
            localizationKey = "GroupHuntingProposedObservation"
            break
        case .accepted:
            localizationKey = "GroupHuntingAcceptedObservation"
            break
        case .rejected:
            localizationKey = "GroupHuntingRejectedObservation"
            break
        default:
            print("Unexpected acceptStatus \(acceptStatus) observed! (falling back to normal Observation)")
            localizationKey = "Observation"
            break
        }

        return localizationKey.localized()
    }


    // MARK: EditGroupObservationListener

    func onObservationApproved() {
        acceptStatus = .accepted

        onObservationUpdated()
    }

    func onObservationUpdated() {
        if let listener = self.listener {
            listener.onObservationUpdated()
        }

        controllerHolder.shouldRefreshViewModel = true
        navigationController?.popToViewController(self, animated: true)
    }

    // MARK: MapExternalIdProvider

    func getMapExternalId() -> String? {
        groupAreaMapExternalId
    }
}
