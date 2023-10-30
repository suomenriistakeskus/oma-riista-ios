import Foundation
import MaterialComponents
import RiistaCommon

class ViewObservationViewController:
    BaseControllerWithViewModel<ViewObservationViewModel, ViewObservationController>,
    ProvidesNavigationController, ModifyObservationViewControllerListener
{
    let observationId: Int64

    private lazy var _controller: ViewObservationController = {
        ViewObservationController(
            observationId: observationId,
            observationContext: RiistaSDK.shared.observationContext,
            userContext: RiistaSDK.shared.currentUserContext,
            metadataProvider: RiistaSDK.shared.metadataProvider,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: ViewObservationController {
        get {
            _controller
        }
    }

    private let tableViewController = DataFieldTableViewController<CommonObservationField>()

    private lazy var editObservationNavBarButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(named: "edit_white"),
            style: .plain,
            target: self,
            action: #selector(onEditObservationClicked)
       )
    }()

    private lazy var deleteObservationNavBarButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(named: "delete_white"),
            style: .plain,
            target: self,
            action: #selector(onDeleteObservationClicked)
       )
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

    @objc init(observationId: Int64) {
        self.observationId = observationId
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

        title = "Observation".localized()

        navigationItem.rightBarButtonItems = [deleteObservationNavBarButton, editObservationNavBarButton]
    }

    override func onViewModelLoaded(viewModel: ViewModelType) {
        super.onViewModelLoaded(viewModel: viewModel)

        updateEditAndDeleteButtonVisibilities(canEdit: viewModel.canEdit)

        tableViewController.setDataFields(dataFields: viewModel.fields)
    }

    private func updateEditAndDeleteButtonVisibilities(canEdit: Bool) {
        editObservationNavBarButton.isHiddenCompat = !canEdit
        deleteObservationNavBarButton.isHiddenCompat = !canEdit
    }

    private func updateEditAndDeleteButtonEnabledStatus(enabled: Bool) {
        editObservationNavBarButton.isEnabled = enabled
        deleteObservationNavBarButton.isEnabled = enabled
    }

    private func onSpeciesImageClicked(fieldId: CommonObservationField, entityImage: EntityImage?) {

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

    @objc private func onEditObservationClicked() {
        guard let editableObservation = controller.getLoadedViewModelOrNull()?.editableObservation else {
            print("Canno edit, no editable observation?")
            return
        }

        let viewController = EditObservationViewController(observation: editableObservation)
        viewController.listener = self
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    func onObservationUpdated() {
        controllerHolder.shouldRefreshViewModel = true
    }

    @objc private func onDeleteObservationClicked() {
        let alertController = MDCAlertController(
            title: "DeleteEntryCaption".localized(),
            message: "DeleteEntryText".localized()
        )
        alertController.addAction(MDCAlertAction(title: "Yes".localized(), handler: { [weak self] _ in
            self?.deleteObservation()
        }))
        alertController.addAction(MDCAlertAction(title: "Cancel".localized(), handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    private func deleteObservation() {
        tableView.showLoading()

        controller.deleteObservation(
            updateToBackend: AppSync.shared.isAutomaticSyncEnabled(),
            completionHandler: handleOnMainThread { [weak self] success, _ in
                guard let self = self else { return }

                self.tableView.hideLoading()
                self.navigationController?.popViewController(animated: true)
            }
        )
    }
}
