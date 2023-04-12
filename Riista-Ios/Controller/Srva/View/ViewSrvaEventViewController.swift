import Foundation
import MaterialComponents
import RiistaCommon

class ViewSrvaEventViewController:
    BaseControllerWithViewModel<ViewSrvaEventViewModel, ViewSrvaEventController>,
    ProvidesNavigationController, ModifySrvaEventViewControllerListener
{
    let srvaEventId: Int64

    private lazy var _controller: ViewSrvaEventController = {
        ViewSrvaEventController(
            srvaEventId: srvaEventId,
            srvaContext: RiistaSDK.shared.srvaContext,
            metadataProvider: RiistaSDK.shared.metadataProvider,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: ViewSrvaEventController {
        get {
            _controller
        }
    }

    private let tableViewController = DataFieldTableViewController<SrvaEventField>()


    private lazy var editSrvaNavBarButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(named: "edit_white"),
            style: .plain,
            target: self,
            action: #selector(onEditSrvaClicked)
       )
    }()

    private lazy var deleteSrvaNavBarButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(named: "delete_white"),
            style: .plain,
            target: self,
            action: #selector(onDeleteSrvaClicked)
       )
    }()

    private(set) lazy var tableView: TableView = {
        let tableView = TableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 70
        tableView.rowHeight = UITableView.automaticDimension

        tableViewController.setTableView(tableView)
        return tableView
    }()

    @objc init(srvaEventId: Int64) {
        self.srvaEventId = srvaEventId
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
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.addDefaultCellFactories(
            navigationControllerProvider: self,
            specimenLauncher: { [weak self] fieldId, specimenData in
                self?.showSpecimens(specimenData: specimenData)
            },
            speciesImageClickListener: { [weak self] fieldId, entityImage in
                self?.onSpeciesImageClicked(fieldId: fieldId, entityImage: entityImage)
            }
        )

        title = "Srva".localized()

        navigationItem.rightBarButtonItems = [deleteSrvaNavBarButton, editSrvaNavBarButton]
    }

    override func onViewModelLoaded(viewModel: ViewModelType) {
        super.onViewModelLoaded(viewModel: viewModel)

        updateEditAndDeleteButtonVisibilities(canEdit: viewModel.canEdit)

        tableViewController.setDataFields(dataFields: viewModel.fields)
    }

    private func updateEditAndDeleteButtonVisibilities(canEdit: Bool) {
        editSrvaNavBarButton.isHidden = !canEdit
        deleteSrvaNavBarButton.isHidden = !canEdit
    }

    private func showSpecimens(specimenData: SpecimenFieldDataContainer) {
        let specimenViewController = ViewSpecimensViewController(specimenData: specimenData)
        self.navigationController?.pushViewController(specimenViewController, animated: true)
    }

    private func onSpeciesImageClicked(fieldId: SrvaEventField, entityImage: EntityImage?) {

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

    @objc private func onEditSrvaClicked() {
        guard let srvaEvent = controller.getLoadedViewModelOrNull()?.editableSrvaEvent else {
            print("Canno edit, no editable srva event?")
            return
        }

        let editSrvaViewController = EditSrvaEventViewController(srvaEvent: srvaEvent)
        editSrvaViewController.listener = self
        self.navigationController?.pushViewController(editSrvaViewController, animated: true)
    }

    func onSrvaEventUpdated() {
        controllerHolder.shouldRefreshViewModel = true
    }

    @objc private func onDeleteSrvaClicked() {
        let alertController = MDCAlertController(
            title: "DeleteEntryCaption".localized(),
            message: "DeleteEntryText".localized()
        )
        alertController.addAction(MDCAlertAction(title: "Yes".localized(), handler: { [weak self] _ in
            self?.deleteSrva()
        }))
        alertController.addAction(MDCAlertAction(title: "Cancel".localized(), handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    private func deleteSrva() {
        tableView.showLoading()

        controller.deleteSrvaEvent(updateToBackend: AppSync.shared.isAutomaticSyncEnabled()) { [weak self] success, _ in
            guard let self = self else { return }

            self.tableView.hideLoading()
            self.navigationController?.popViewController(animated: true)
        }
    }
}
