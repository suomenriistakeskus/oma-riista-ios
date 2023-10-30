import Foundation
import DropDown
import MaterialComponents
import RiistaCommon


fileprivate let HARVEST_SETTINGS: Int = 1

class ViewHarvestViewController:
    BaseControllerWithViewModel<ViewHarvestViewModel, ViewHarvestController>,
    ProvidesNavigationController, ModifyHarvestViewControllerListener
{
    let harvestId: Int64

    private lazy var _controller: ViewHarvestController = {
        ViewHarvestController(
            harvestId: harvestId,
            harvestContext: RiistaSDK.shared.harvestContext,
            harvestSeasons: RiistaSDK.shared.harvestSeasons,
            speciesResolver: SpeciesInformationResolver(),
            harvestPermitProvider: AppHarvestPermitProvider(),
            preferences: RiistaSDK.shared.preferences,
            stringProvider: LocalizedStringProvider(),
            languageProvider: CurrentLanguageProvider()
        )
    }()

    override var controller: ViewHarvestController {
        get {
            _controller
        }
    }

    private let tableViewController = DataFieldTableViewController<CommonHarvestField>()

    private lazy var editHarvestNavBarButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(named: "edit_white"),
            style: .plain,
            target: self,
            action: #selector(onEditHarvestClicked)
       )
    }()

    private lazy var deleteHarvestNavBarButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(named: "delete_white"),
            style: .plain,
            target: self,
            action: #selector(onDeleteHarvestClicked)
       )
    }()

    private lazy var moreMenuNavBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(named: "more_menu"),
            style: .plain,
            target: self,
            action: #selector(onMoreMenuItemClicked)
        )
        return button
    }()

    private lazy var moreMenuItems: DropdownItemProvider = {
        let provider = DropdownItemProvider()
        provider.addItem(DropdownItem(
            id: HARVEST_SETTINGS,
            title: "HarvestSettings".localized(),
            hidden: false,
            onClicked: { [weak self] in
                self?.onHarvestSettingsClicked()
            }
        ))
        return provider
    }()

    private(set) lazy var tableView: TableView = {
        let tableView = TableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension

        tableViewController.setTableView(tableView)
        return tableView
    }()

    @objc init(harvestId: Int64) {
        self.harvestId = harvestId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func loadView() {
        super.loadView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.addDefaultCellFactories(
            navigationControllerProvider: self,
            specimenLauncher: { [weak self] fieldId, specimenData, allowEdit in
                SpecimensViewControllerLauncher.launch(
                    parent: self,
                    fieldId: fieldId,
                    specimenData: specimenData,
                    allowEdit: allowEdit,
                    onSpecimensEditDone: nil
                )
            },
            speciesImageClickListener: { [weak self] fieldId, entityImage in
                self?.onSpeciesImageClicked(fieldId: fieldId, entityImage: entityImage)
            }
        )

        title = "Harvest".localized()

        navigationItem.rightBarButtonItems = [moreMenuNavBarButton, deleteHarvestNavBarButton, editHarvestNavBarButton]
    }

    override func onViewModelLoaded(viewModel: ViewModelType) {
        super.onViewModelLoaded(viewModel: viewModel)

        updateEditAndDeleteButtonVisibilities(canEdit: viewModel.canEdit)

        tableViewController.setDataFields(dataFields: viewModel.fields)
    }

    private func updateEditAndDeleteButtonVisibilities(canEdit: Bool) {
        editHarvestNavBarButton.isHiddenCompat = !canEdit
        deleteHarvestNavBarButton.isHiddenCompat = !canEdit
    }

    private func updateEditAndDeleteButtonEnabledStatus(enabled: Bool) {
        editHarvestNavBarButton.isEnabled = enabled
        deleteHarvestNavBarButton.isEnabled = enabled
    }

    private func onSpeciesImageClicked(fieldId: CommonHarvestField, entityImage: EntityImage?) {

        guard let entityImage = entityImage else {
            return
        }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let dest = sb.instantiateViewController(withIdentifier: "ImageFullController") as! ImageFullViewController
        dest.entityImage = entityImage

        let segue = UIStoryboardSegue(identifier: "", source: self, destination: dest, performHandler: {
            self.navigationController?.pushViewController(dest, animated: true)
        })
        segue.perform()
    }

    @objc private func onEditHarvestClicked() {
        guard let editableHarvest = controller.getLoadedViewModelOrNull()?.editableHarvest else {
            print("Canno edit, no editable harvest?")
            return
        }

        let viewController = EditHarvestViewController(harvest: editableHarvest)
        viewController.listener = self
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    func onHarvestUpdated() {
        controllerHolder.shouldRefreshViewModel = true
    }

    @objc private func onDeleteHarvestClicked() {
        let alertController = MDCAlertController(
            title: "DeleteEntryCaption".localized(),
            message: "DeleteEntryText".localized()
        )
        alertController.addAction(MDCAlertAction(title: "Yes".localized(), handler: { [weak self] _ in
            self?.deleteHarvest()
        }))
        alertController.addAction(MDCAlertAction(title: "Cancel".localized(), handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    private func deleteHarvest() {
        tableView.showLoading()

        controller.deleteHarvest(
            updateToBackend: AppSync.shared.isAutomaticSyncEnabled(),
            completionHandler: handleOnMainThread { [weak self] success, _ in
                guard let self = self else { return }

                self.tableView.hideLoading()
                self.navigationController?.popViewController(animated: true)
            }
        )
    }

    @objc private func onMoreMenuItemClicked() {
        let dropDown = DropDown()
        dropDown.anchorView = moreMenuNavBarButton
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y: moreMenuNavBarButton.plainView.bounds.height)
        dropDown.setDataSource(using: moreMenuItems)
        dropDown.selectionAction = { [weak self] (index: Int, _: String) in
            self?.moreMenuItems.onItemSelected(index: index)
        }

        dropDown.show()
    }

    private func onHarvestSettingsClicked() {
        // changing settings may affect how data is displayed -> refresh when returning
        controllerHolder.shouldRefreshViewModel = true

        let viewController = HarvestSettingsViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}
