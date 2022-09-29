import Foundation
import MaterialComponents
import RiistaCommon

class ViewSrvaEventViewController:
    BaseControllerWithViewModel<ViewSrvaEventViewModel, ViewSrvaEventController>,
    ProvidesNavigationController
{

    private lazy var _controller: ViewSrvaEventController = {
        ViewSrvaEventController(
            metadataProvider: RiistaSDK.shared.metadataProvider,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: ViewSrvaEventController {
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

    private let tableViewController = DataFieldTableViewController<SrvaEventField>()
    var srvaEvent: CommonSrvaEvent

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

    @objc init(srvaEvent: CommonSrvaEvent) {
        self.srvaEvent = srvaEvent
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
    }

    override func viewWillAppear(_ animated: Bool) {
        controllerHolder.bindToViewModelLoadStatus()

        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItems = [deleteSrvaNavBarButton, editSrvaNavBarButton]

        // Reload srva event, user might have edited it
        guard let localUri = srvaEvent.localUrl,
              let uri = URL(string: localUri),
              let objectId = moContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                  print("Unable to retrieve objectID")
                  return
        }

        if let srvaEntry = RiistaGameDatabase.sharedInstance().srvaEntry(with: objectId, context: moContext) {
            self.moContext.refresh(srvaEntry, mergeChanges: true)

            if let srvaEvent = srvaEntry.toSrvaEvent(objectId: objectId) {
                self.srvaEvent = srvaEvent
                controller.srvaEvent = self.srvaEvent

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
        let editSrvaViewController = EditSrvaEventViewController(srvaEvent: srvaEvent)
        self.navigationController?.pushViewController(editSrvaViewController, animated: false)
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
        guard let localUri = srvaEvent.localUrl,
              let uri = URL(string: localUri),
              let objectId = moContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                  print("Unable to retrieve objectID")
                  return
          }

        let entry = RiistaGameDatabase.sharedInstance().srvaEntry(with: objectId, context: moContext)
        SrvaSaveOperations.sharedInstance().deleteSrva(entry)
        navigationController?.popViewController(animated: true)
    }
}
