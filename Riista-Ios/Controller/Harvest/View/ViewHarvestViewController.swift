import Foundation
import MaterialComponents
import RiistaCommon

class ViewHarvestViewController:
    BaseControllerWithViewModel<ViewHarvestViewModel, ViewHarvestController>,
    ProvidesNavigationController, ModifyHarvestCompletionListener
{

    private lazy var _controller: ViewHarvestController = {
        ViewHarvestController(
            harvestSeasons: RiistaSDK.shared.harvestSeasons,
            speciesResolver: SpeciesInformationResolver(),
            permitProvider: AppPermitProvider(),
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: ViewHarvestController {
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

    private let tableViewController = DataFieldTableViewController<CommonHarvestField>()
    var harvest: CommonHarvest

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

    @objc init(harvest: CommonHarvest) {
        self.harvest = harvest
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

        title = "Harvest".localized()
    }

    override func viewWillAppear(_ animated: Bool) {
        controllerHolder.bindToViewModelLoadStatus()

        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItems = [
            deleteHarvestNavBarButton,
            editHarvestNavBarButton
        ]

        // Reload harvest, user might have edited it
        guard let localUri = harvest.localUrl,
              let uri = URL(string: localUri),
              let objectId = moContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                  print("Unable to retrieve objectID")
                  return
        }

        if let harvestEntry = RiistaGameDatabase.sharedInstance().diaryEntry(with: objectId, context: moContext) {
            self.moContext.refresh(harvestEntry, mergeChanges: true)

            if let commonHarvest = harvestEntry.toCommonHarvest(objectId: objectId) {
                self.harvest = commonHarvest
                controller.harvest = commonHarvest

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
        editHarvestNavBarButton.isHidden = !canEdit
        deleteHarvestNavBarButton.isHidden = !canEdit
    }

    private func updateEditAndDeleteButtonEnabledStatus(enabled: Bool) {
        editHarvestNavBarButton.isEnabled = enabled
        deleteHarvestNavBarButton.isEnabled = enabled
    }

    private func showSpecimens(specimenData: SpecimenFieldDataContainer) {
        let specimenViewController = ViewSpecimensViewController(specimenData: specimenData)
        self.navigationController?.pushViewController(specimenViewController, animated: true)
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
        let viewController = EditHarvestViewController(harvest: harvest)
        self.navigationController?.pushViewController(viewController, animated: true)
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
        guard let localUri = harvest.localUrl,
              let uri = URL(string: localUri),
              let objectId = moContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                  print("Unable to retrieve objectID, cannot delete harvest")
                  return
          }

        guard let harvestEntry = RiistaGameDatabase.sharedInstance().diaryEntry(with: objectId, context: moContext) else {
            print("Couldn't find harvest, cannot delete")
            return
        }

        RiistaGameDatabase.sharedInstance().deleteLocalEvent(harvestEntry)

        if (deleteHarvestIfLocalOnly(harvest: harvestEntry)) {
            navigationController?.popViewController(animated: true)
            return
        }

        if (SynchronizationMode.currentValue == .automatic) {
            tableView.showLoading()
            updateEditAndDeleteButtonEnabledStatus(enabled: false)

            RiistaGameDatabase.sharedInstance().deleteDiaryEntryCompat(harvestEntry) { [weak self] wasSuccess in
                self?.tableView.hideLoading { [weak self] in
                    if (wasSuccess) {
                        self?.deleteLocalHarvest(harvest: harvestEntry)
                        self?.navigationController?.popViewController(animated: true)
                    } else {
                        self?.updateEditAndDeleteButtonEnabledStatus(enabled: true)

                        let errorDialog = AlertDialogBuilder.createError(message: "NetworkOperationFailed".localized())
                        self?.present(errorDialog, animated: true)
                    }
                }
            }
        } else {
            navigationController?.popViewController(animated: true)
        }
    }


    private func deleteHarvestIfLocalOnly(harvest: DiaryEntry) -> Bool {
        if (harvest.remote?.boolValue == true) {
            return false
        }

        deleteLocalHarvest(harvest: harvest)
        return true
    }

    private func deleteLocalHarvest(harvest: DiaryEntry) {
        harvest.managedObjectContext?.performAndWait {
            harvest.managedObjectContext?.delete(harvest)
            harvest.managedObjectContext?.performAndWait {
                try? harvest.managedObjectContext?.save()

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

    func updateUserInterfaceAfterHarvestSaved() {
        self.navigationController?.popToViewController(self, animated: false)

        // also pop this view controller as harvest id (in coredata) may change when it
        // is synchronized to the backend -> it cannot be modified again
        // TODO: figure out a way to remove this limitation
        self.navigationController?.popViewController(animated: true)
    }
}
