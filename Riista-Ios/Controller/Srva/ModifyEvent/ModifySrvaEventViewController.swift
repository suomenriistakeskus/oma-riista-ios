import Foundation
import RiistaCommon
import CoreData

class ModifySrvaEventViewController<Controller: ModifySrvaEventController>:
    BaseControllerWithViewModel<ModifySrvaEventViewModel, Controller>,
    ProvidesNavigationController,
    KeyboardHandlerDelegate,
    RiistaImagePickerDelegate {

    private let tableViewController = DataFieldTableViewController<SrvaEventField>()
    private var keyboardHandler: KeyboardHandler?

    private lazy var appDelegate: RiistaAppDelegate = {
        return UIApplication.shared.delegate as! RiistaAppDelegate
    }()

    internal lazy var moContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        context.parent = appDelegate.managedObjectContext
        return context
    }()

    private lazy var imageEditUtil: ImageEditUtil = {
        ImageEditUtil(parentController: self)
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

    private lazy var buttonArea: UIView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = 8
        view.backgroundColor = UIColor.applicationColor(ViewBackground)
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = AppConstants.UI.DefaultEdgeInsets

        view.addArrangedSubview(cancelButton)
        view.addArrangedSubview(saveButton)
        view.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight + view.layoutMargins.top + view.layoutMargins.bottom)
        }

        let separator = SeparatorView(orientation: .horizontal)
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        return view
    }()

    private lazy var cancelButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyOutlinedTheme(withScheme: AppTheme.shared.outlineButtonScheme())
        btn.setTitle("Cancel".localized(), for: .normal)
        btn.onClicked = { [weak self] in
            self?.onCancelClicked()
        }
        return btn
    }()

    private(set) lazy var saveButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        btn.setTitle(getSaveButtonTitle(), for: .normal)
        btn.onClicked = { [weak self] in
            self?.onSaveClicked()
        }
        return btn
    }()

    @objc init() {
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

        container.addArrangedSubview(tableView)
        container.addArrangedSubview(buttonArea)

        keyboardHandler = KeyboardHandler(
            view: view,
            contentMovement: .adjustContentInset(scrollView: tableView)
        )
        keyboardHandler?.delegate = self
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.addDefaultCellFactories(
            navigationControllerProvider: self,
            locationEventDispatcher: controller.eventDispatchers.locationEventDispatcher,
            stringWithIdEventDispatcher: controller.eventDispatchers.stringWithIdEventDispatcher,
            stringEventDispatcher: controller.eventDispatchers.stringEventDispatcher,
            booleanEventDispatcher: controller.eventDispatchers.booleanEventDispatcher,
            intEventDispatcher: controller.eventDispatchers.intEventDispatcher,
            localDateTimeEventDispacter: controller.eventDispatchers.localDateTimeEventDispatcher,
            specimenLauncher: { [weak self] fieldId, specimenData in
                self?.showSpecimen(fieldId: fieldId, specimenData: specimenData)
            },
            speciesEventDispatcher: controller.eventDispatchers.speciesEventDispatcher,
            speciesImageClickListener: { [weak self] fieldId, entityImage in
                self?.onSpeciesImageClicked(fieldId: fieldId, entityImage: entityImage)
            }
        )

        title = getViewTitle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        keyboardHandler?.listenKeyboardEvents()
    }

    override func viewWillDisappear(_ animated: Bool) {
        keyboardHandler?.hideKeyboard()
        keyboardHandler?.stopListenKeyboardEvents()

        super.viewWillDisappear(animated)
    }

    override func onViewModelLoaded(viewModel: ViewModelType) {
        super.onViewModelLoaded(viewModel: viewModel)

        tableViewController.setDataFields(dataFields: viewModel.fields)

        saveButton.isEnabled = viewModel.srvaEventIsValid
    }

    override func onViewModelLoadFailed() {
        super.onViewModelLoadFailed()
    }

    private func showSpecimen(fieldId: DataFieldId, specimenData: SpecimenFieldDataContainer) {
        let specimenViewController = EditSpecimensViewController(fieldId: fieldId, specimenData: specimenData)
        specimenViewController.onSpecimensEditDone = onSpecimensEditDone
        self.navigationController?.pushViewController(specimenViewController, animated: true)
    }

    private func onSpeciesImageClicked(fieldId: SrvaEventField, entityImage: EntityImage?) {
        imageEditUtil.checkPhotoPermissions { [weak self] in
            guard let self = self else { return }
            self.imageEditUtil.editImage(pickerDelegate: self)
        }
    }

    func imagePicked(image: IdentifiableImage) {
        let entityImage = EntityImage(
            serverId: UUID().uuidString, // generate one
            localIdentifier: image.imageIdentifier.localIdentifier,
            localUrl: image.imageIdentifier.imageUrl?.absoluteString,
            status: .local
        )
        controller.eventDispatchers.imageEventDispatcher.setEntityImage(image: entityImage)
    }

    func imagePickCancelled() {
        // nop
    }

    func imagePickFailed(_ reason: PhotoAccessFailureReason, loadRequest: ImageLoadRequest?) {
        imageEditUtil.displayImageLoadFailedDialog(
            self, reason: reason, imageLoadRequest: loadRequest, allowAnotherPhotoSelection: true)
    }

    func onSaveClicked() {
        fatalError("You should subclass this class and override onSaveClicked()")
    }

    func onCancelClicked() {
        navigationController?.popViewController(animated: true)
    }

    func getSaveButtonTitle() -> String {
        return "Save".localized()
    }

    func getViewTitle() -> String {
        return "Edit".localized()
    }

    func onSpecimensEditDone(fieldId: DataFieldId, specimenData: SpecimenFieldDataContainer) {
        controller.eventDispatchers.specimenEventDispatcher.dispatchSpecimenDataChanged(
            fieldId: fieldId,
            value: specimenData
        )
    }

    internal func newImages(_ srvaEvent: CommonSrvaEvent) -> [DiaryImage] {
        var newImages = [DiaryImage]()
        srvaEvent.images.localImages.forEach { image in
            if (image.status == .local) {
                let diaryImage = image.toDiaryImage(context: moContext)
                diaryImage.imageid = NSUUID().uuidString
                diaryImage.status = NSNumber(value: DiaryImageStatusInsertion)
                newImages.append(diaryImage)
            }
        }
        return newImages
    }

    // MARK: KeyboardHandlerDelegate

    func getBottommostVisibleViewWhileKeyboardVisible() -> UIView? {
        tableView
    }

}
