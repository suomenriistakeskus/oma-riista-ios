import Foundation
import RiistaCommon
import CoreData

protocol ModifySrvaEventViewControllerListener: AnyObject {
    func onSrvaEventUpdated()
}

class ModifySrvaEventViewController<Controller: ModifySrvaEventController>:
    BaseControllerWithViewModel<ModifySrvaEventViewModel, Controller>,
    ProvidesNavigationController,
    KeyboardHandlerDelegate,
    RiistaImagePickerDelegate {

    private let tableViewController = DataFieldTableViewController<SrvaEventField>()
    private var keyboardHandler: KeyboardHandler?

    // prevent appsync while modifying
    private lazy var appsyncPreventer = PreventAppSyncWhileModifyingSynchronizableEntry(viewController: self)

    private lazy var imageEditUtil: ImageEditUtil = ImageEditUtil(parentController: self)
    private lazy var commonImageManager: CommonImageManager = CommonImageManager()

    /**
     * Listener to be notified when srva event is updated.
     */
    weak var listener: ModifySrvaEventViewControllerListener?


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
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
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
            specimenLauncher: { [weak self] fieldId, specimenData, allowEdit in
                SpecimensViewControllerLauncher.launch(
                    parent: self,
                    fieldId: fieldId,
                    specimenData: specimenData,
                    allowEdit: allowEdit,
                    onSpecimensEditDone: self?.onSpecimensEditDone
                )
            },
            speciesEventDispatcher: controller.eventDispatchers.speciesEventDispatcher,
            speciesImageClickListener: { [weak self] fieldId, entityImage in
                self?.onSpeciesImageClicked(fieldId: fieldId, entityImage: entityImage)
            },
            selectSpeciesAndImageFieldCellEntryType: .srva
        )

        title = getViewTitle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        appsyncPreventer.onViewWillAppear()
        keyboardHandler?.listenKeyboardEvents()
    }

    override func viewWillDisappear(_ animated: Bool) {
        keyboardHandler?.hideKeyboard()
        keyboardHandler?.stopListenKeyboardEvents()
        appsyncPreventer.onViewWillDisappear()

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

    private func onSpeciesImageClicked(fieldId: SrvaEventField, entityImage: EntityImage?) {
        imageEditUtil.checkPhotoPermissions { [weak self] in
            guard let self = self else { return }
            self.imageEditUtil.editImage(pickerDelegate: self)
        }
    }


    // MARK: Handling images

    func imagePicked(image: IdentifiableImage) {
        guard let entityImage = commonImageManager.saveImageToTemporaryImages(identifiableImage: image) else {
            print("Failed to obtain entity image")
            return
        }

        controller.eventDispatchers.imageEventDispatcher.setEntityImage(image: entityImage)
    }

    func imagePickCancelled() {
        // nop
    }

    func imagePickFailed(_ reason: PhotoAccessFailureReason, loadRequest: ImageLoadRequest?) {
        imageEditUtil.displayImageLoadFailedDialog(
            self, reason: reason, imageLoadRequest: loadRequest, allowAnotherPhotoSelection: true)
    }

    func saveImagesUnderLocalImages(srvaEvent: CommonSrvaEvent, _ onCompleted: @escaping OnCompleted) {
        let imagesToKeep = srvaEvent.images.localImages.filter { entityImage in
            entityImage.status == .local
        }

        commonImageManager.moveTemporaryImagesToLocalImages(images: imagesToKeep, onCompleted: onCompleted)
    }


    // MARK: Save & cancel

    func onSaveClicked() {
        tableView.showLoading()
        saveButton.isEnabled = false


        controller.saveSrvaEvent(
            updateToBackend: AppSync.shared.isAutomaticSyncEnabled(),
            completionHandler: handleOnMainThread { [weak self] response, error in
                guard let self = self else { return }

                self.tableView.hideLoading()
                self.saveButton.isEnabled = true

                // notify possible parent about saved srva event
                self.listener?.onSrvaEventUpdated()

                let databaseSaveResponse = response?.databaseSaveResponse
                let networkSaveResponse = response?.networkSaveResponse

                if let networkFailure = networkSaveResponse as? SrvaEventOperationResponse.NetworkFailure,
                   networkFailure.statusCode == 409 {
                    let errorDialog = AlertDialogBuilder.createError(message: "OutdatedDiaryEntry".localized())
                    self.present(errorDialog, animated: true)
                } else if let successResponse = databaseSaveResponse as? SrvaEventOperationResponse.Success {
                    self.handleSuccessfullySavedSrvaEvent(srvaEvent: successResponse.srvaEvent)
                } else {
                    let errorDialog = AlertDialogBuilder.createError(message: "DiaryEditFailed".localized())
                    self.present(errorDialog, animated: true)
                }
            }
        )
    }

    private func handleSuccessfullySavedSrvaEvent(srvaEvent: CommonSrvaEvent) {
        NotificationCenter.default.post(EntityModified(
            object: EntityModified.Data(
                entityType: .srva,
                entityPointOfTime: srvaEvent.pointOfTime,
                entitySpecies: srvaEvent.species,
                entityReportedForOthers: false // currently not possible
            )
        ))

        saveImagesUnderLocalImages(srvaEvent: srvaEvent) { [weak self] in
            self?.navigateToNextViewAfterSaving(srvaEvent: srvaEvent)
        }
    }

    func navigateToNextViewAfterSaving(srvaEvent: CommonSrvaEvent) {
        fatalError("You should subclass this class and override navigateToNextViewAfterSaving(srvaEvent:)")
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


    // MARK: KeyboardHandlerDelegate

    func getBottommostVisibleViewWhileKeyboardVisible() -> UIView? {
        tableView
    }
}
