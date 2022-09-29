import Foundation
import MaterialComponents
import RiistaCommon

class ViewObservationViewController:
    BaseControllerWithViewModel<ViewObservationViewModel, ViewObservationController>,
    ProvidesNavigationController, ModifyObservationCompletionListener
{

    private lazy var _controller: ViewObservationController = {
        ViewObservationController(
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

    private lazy var appDelegate: RiistaAppDelegate = {
        return UIApplication.shared.delegate as! RiistaAppDelegate
    }()

    internal lazy var moContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        context.parent = appDelegate.managedObjectContext
        return context
    }()

    private let tableViewController = DataFieldTableViewController<CommonObservationField>()
    var observation: CommonObservation

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
        tableView.estimatedRowHeight = 70
        tableView.rowHeight = UITableView.automaticDimension

        tableViewController.setTableView(tableView)
        return tableView
    }()

    @objc init(observation: CommonObservation) {
        self.observation = observation
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

        title = "Observation".localized()
    }

    override func viewWillAppear(_ animated: Bool) {
        controllerHolder.bindToViewModelLoadStatus()

        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItems = [deleteObservationNavBarButton, editObservationNavBarButton]

        // Reload observation, user might have edited it
        guard let localUri = observation.localUrl,
              let uri = URL(string: localUri),
              let objectId = moContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                  print("Unable to retrieve objectID")
                  return
        }

        if let observationEntry = RiistaGameDatabase.sharedInstance().observationEntry(with: objectId, context: moContext) {
            self.moContext.refresh(observationEntry, mergeChanges: true)

            if let commonObservation = observationEntry.toCommonObservation(objectId: objectId) {
                self.observation = commonObservation
                controller.observation = commonObservation

                controllerHolder.loadViewModel(refresh: controllerHolder.shouldRefreshViewModel)
            }
        }
    }

    override func onViewModelLoaded(viewModel: ViewModelType) {
        super.onViewModelLoaded(viewModel: viewModel)

        updateEditAndDeleteButtonVisibilities(canEdit: viewModel.canEdit)

        tableViewController.setDataFields(dataFields: viewModel.fields)
    }

    private func updateEditAndDeleteButtonVisibilities(canEdit: Bool) {
        editObservationNavBarButton.isHidden = !canEdit
        deleteObservationNavBarButton.isHidden = !canEdit
    }

    private func updateEditAndDeleteButtonEnabledStatus(enabled: Bool) {
        editObservationNavBarButton.isEnabled = enabled
        deleteObservationNavBarButton.isEnabled = enabled
    }

    private func showSpecimens(specimenData: SpecimenFieldDataContainer) {
        let specimenViewController = ViewSpecimensViewController(specimenData: specimenData)
        self.navigationController?.pushViewController(specimenViewController, animated: true)
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
        let viewController = EditObservationViewController(observation: observation)
        self.navigationController?.pushViewController(viewController, animated: true)
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
        guard let localUri = observation.localUrl,
              let uri = URL(string: localUri),
              let objectId = moContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                  print("Unable to retrieve objectID, cannot delete observation")
                  return
          }

        guard let observationEntry = RiistaGameDatabase.sharedInstance().observationEntry(with: objectId, context: moContext) else {
            print("Couldn't find observation, cannot delete")
            return
        }

        RiistaGameDatabase.sharedInstance().deleteLocalObservation(observationEntry)

        if (deleteObservationIfLocalOnly(observation: observationEntry)) {
            navigationController?.popViewController(animated: true)
            return
        }

        if (RiistaSettings.syncMode() == RiistaSyncModeAutomatic) {
            tableView.showLoading()
            updateEditAndDeleteButtonEnabledStatus(enabled: false)

            RiistaGameDatabase.sharedInstance().deleteObservationEntryCompat(observationEntry) { [weak self] wasSuccess in
                self?.tableView.hideLoading { [weak self] in
                    if (wasSuccess) {
                        self?.deleteLocalObservation(observation: observationEntry)
                        self?.navigationController?.popViewController(animated: true)
                    } else {
                        self?.updateEditAndDeleteButtonEnabledStatus(enabled: true)

                        let errorDialog = AlertDialogBuilder.createError(message: "NetworkOperationFailed".localized())
                        self?.present(errorDialog, animated: true)
                    }
                }
            }
        }
    }

    private func deleteObservationIfLocalOnly(observation: ObservationEntry) -> Bool {
        if (observation.remote?.boolValue == true) {
            return false
        }

        deleteLocalObservation(observation: observation)
        return true
    }

    private func deleteLocalObservation(observation: ObservationEntry) {
        observation.managedObjectContext?.performAndWait {
            observation.managedObjectContext?.delete(observation)
            observation.managedObjectContext?.performAndWait {
                try? observation.managedObjectContext?.save()

                if let appDelegate = UIApplication.shared.delegate as? RiistaAppDelegate {
                    appDelegate.managedObjectContext.performAndWait {
                        try? appDelegate.managedObjectContext.save()
                    }
                } else {
                    print("Failed to obtain app delegate for saving managed object contexts.")
                }
            }
        }
    }

    func updateUserInterfaceAfterObservationSaved() {
        self.navigationController?.popToViewController(self, animated: false)

        // also pop this view controller as observation id (in coredata) may change when it
        // is synchronized to the backend -> it cannot be modified again
        self.navigationController?.popViewController(animated: true)
    }
}
