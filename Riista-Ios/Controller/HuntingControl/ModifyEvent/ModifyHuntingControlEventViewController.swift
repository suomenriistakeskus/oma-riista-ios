import Foundation
import UIKit
import SnapKit
import RiistaCommon
import UniformTypeIdentifiers
import MobileCoreServices
import MaterialComponents


class ModifyHuntingControlEventViewController<Controller: ModifyHuntingControlEventController>:
    BaseControllerWithViewModel<ModifyHuntingControlEventViewModel, Controller>,
    ProvidesNavigationController,
    KeyboardHandlerDelegate,
    AttachmentFieldStatusProvider,
    RiistaImagePickerDelegate,
    UIDocumentPickerDelegate {

    let huntingControlRhyTarget: HuntingControlRhyTarget

    private let tableViewController = DataFieldTableViewController<HuntingControlEventField>()
    private var keyboardHandler: KeyboardHandler?

    // attachments

    private lazy var attachmentOpenHelper: HuntingControlAttachmentOpenHelper = {
        HuntingControlAttachmentOpenHelper(parentViewController: self)
    }()

    private var selectingAttachmentForField: HuntingControlEventField?

    private lazy var imageEditUtil: ImageEditUtil = {
        ImageEditUtil(parentController: self)
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

    init(huntingControlRhyTarget: HuntingControlRhyTarget) {
        self.huntingControlRhyTarget = huntingControlRhyTarget
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
            stringClickEventDispatcher: controller.eventDispatchers.stringWithIdClickEventDispatcher,
            stringEventDispatcher: controller.eventDispatchers.stringEventDispatcher,
            booleanEventDispatcher: controller.eventDispatchers.booleanEventDispatcher,
            intEventDispatcher: controller.eventDispatchers.intEventDispatcher,
            localDateEventDispatcher: controller.eventDispatchers.localDateEventDispatcher,
            localTimeEventDispatcher: controller.eventDispatchers.localTimeEventDispatcher,
            attachmentClickListener: onAttachmentClicked,
            attachmentRemoveListener: onAttachmentRemoveClicked,
            attachmentStatusProvider: self,
            buttonClickHandler: { [weak self] fieldId in
                self?.handleButtonClick(fieldId: fieldId)
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

        saveButton.isEnabled = viewModel.eventIsValid
    }

    override func onViewModelLoadFailed() {
        super.onViewModelLoadFailed()
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

    private func handleButtonClick(fieldId: HuntingControlEventField) {
        switch (fieldId.type) {
        case .addAttachment:
            selectAttachmentPickMethod()
        default:
            print("Unknown field clicked \(fieldId.type)")
        }
    }

    private func selectAttachmentPickMethod() {

        var attachmentSources: [SelectAttachmentSourceDialogController.AttachmentSource] = []
        if (imageEditUtil.canTakePhoto()) {
            attachmentSources.append(.takePhoto)
        }
        attachmentSources.append(.pickFromPhotos)
        attachmentSources.append(.pickFile)

        if (attachmentSources.count == 1) {
            // no need to display dialog, only one possibility here
            continueAttachmentSelection(attachmentSource: attachmentSources.first!)
            return
        }


        let dialogController = SelectAttachmentSourceDialogController()
        dialogController.allowedAttachmentSources = attachmentSources

        dialogController.listener = { [weak self] attachmentSource in
            guard let self = self else { return }
            self.continueAttachmentSelection(attachmentSource: attachmentSource)
        }

        present(dialogController, animated: true, completion:nil)
    }

    private func continueAttachmentSelection(attachmentSource: SelectAttachmentSourceDialogController.AttachmentSource) {
        switch (attachmentSource) {
        case .takePhoto:
            imageEditUtil.takePhoto(pickerDelegate: self)
        case .pickFromPhotos:
            imageEditUtil.checkPhotoPermissions { [weak self] in
                guard let self = self else { return }
                self.imageEditUtil.pickImageFromGallery(pickerDelegate: self)
            }
        case .pickFile:
            pickAttachment()
        }
    }

    func imagePicked(image: IdentifiableImage) {
        print("image picked, adding")
        addImageAsAnAttachment(image: image.image)
    }

    func imagePickCancelled() {
        // nop
    }

    func imagePickFailed(_ reason: PhotoAccessFailureReason, loadRequest: ImageLoadRequest?) {
        imageEditUtil.displayImageLoadFailedDialog(
            self, reason: reason, imageLoadRequest: loadRequest, allowAnotherPhotoSelection: true)
    }

    private func pickAttachment() {
        let types: [String] = [kUTTypeContent, kUTTypeData, kUTTypeArchive] as [String]

        // IMPORTANT: use .import as mode as that copies the file under application tmp directory.
        // -> we can then move the file to proper location
        let documentPicker = UIDocumentPickerViewController(documentTypes: types, in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .pageSheet
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if (!urls.isEmpty) {
            addFileAsAnAttachment(url: urls.first!)
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        addFileAsAnAttachment(url: url)
    }

    private func addImageAsAnAttachment(image: UIImage) {
        let filename = "IMG_\(IMAGE_DATE_FORMATTER.string(from: Date())).jpg"
        let mimetype = "image/jpeg"
        let fileUuid = UUID().uuidString

        guard let targetFilePath = CommonFileStorage.shared.getPathFor(directory: .temporaryFiles, fileUuid: fileUuid) else {
            print("Could not obtain target file path for the image")
            return
        }
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Could not obtain target image data, cannot write to file")
            return
        }

        let targetFileUrl = URL(fileURLWithPath: targetFilePath)

        do {
            try imageData.write(to: targetFileUrl, options: [.atomic])
        } catch {
            print("Failed to save file")
            return
        }

        let thumbnailImage = createThumbnail(originalImage: image)
        let thumbnailImageBase64 = thumbnailImage?.jpegData(compressionQuality: 1)?.base64EncodedString()

        let attachment = HuntingControlAttachment(
            localId: nil,
            remoteId: nil,
            fileName: filename,
            isImage: thumbnailImage != nil,
            thumbnailBase64: thumbnailImageBase64,
            deleted: false,
            uuid: fileUuid,
            mimeType: mimetype
        )

        controller.eventDispatchers.attachmentEventDispatcher.addAttachment(attachment: attachment)
    }

    private func addFileAsAnAttachment(url: URL) {
        let originalFilename = url.lastPathComponent
        let mimetype = url.mimeType()
        let fileUuid = UUID().uuidString
        let thumbnailImage = createThumbnail(url: url, mimeType: mimetype)
        let thumbnailImageBase64 = thumbnailImage?.jpegData(compressionQuality: 1)?.base64EncodedString()

        CommonFileStorage.shared.moveFileToTemporaryFilesDirectory(sourceFileUrl: url, fileUuid: fileUuid)

        let attachment = HuntingControlAttachment(
            localId: nil,
            remoteId: nil,
            fileName: originalFilename,
            isImage: thumbnailImage != nil,
            thumbnailBase64: thumbnailImageBase64,
            deleted: false,
            uuid: fileUuid,
            mimeType: mimetype
        )

        controller.eventDispatchers.attachmentEventDispatcher.addAttachment(attachment: attachment)
    }

    private func createThumbnail(url: URL, mimeType: String) -> UIImage? {
        if (!mimeType.starts(with: "image/")) {
            print("Not going to create a thumbnail for mimetype \(mimeType)")
            return nil
        }

        guard let image = UIImage(contentsOfFile: url.path) else {
            print("Failed to open image at \(url.path). Not creating thumbnail for mimeType \(mimeType)")
            return nil
        }

        return createThumbnail(originalImage: image)
    }

    private func createThumbnail(originalImage: UIImage) -> UIImage? {
        return originalImage.resizedImageToFit(in: CGSize(width: 50, height: 50), scaleIfSmaller: false)
    }


    private func onAttachmentClicked(fieldId: HuntingControlEventField) {
        guard let attachment = controller.getAttachment(field: fieldId) else {
            print("Failed to obtain attachment, cannot open")
            return
        }

        attachmentOpenHelper.openAttachment(attachment: attachment)
    }

    func getAttachmentDownloadStatus(fieldId: Int) -> DownloadStatus {
        guard let field = HuntingControlEventField.companion.fromInt(value: Int32(fieldId)),
                let attachment = controller.getAttachment(field: field) else {
            print("Failed to obtain attachment, cannot optain download status")
            return .notDownloaded
        }

        return attachmentOpenHelper.getAttachmentDownloadStatus(attachment: attachment)
    }

    func listenForAttachmentDownloadStatusChanges(fieldId: Int, listener: @escaping AttachmentDownloadStatusListener) {
        guard let field = HuntingControlEventField.companion.fromInt(value: Int32(fieldId)),
                let attachment = controller.getAttachment(field: field) else {
            print("Failed to obtain attachment, cannot register listener")
            return
        }

        attachmentOpenHelper.listenForAttachmentDownloadStatusChanges(
            fieldId: fieldId, attachment: attachment, listener: listener)
    }


    private func onAttachmentRemoveClicked(fieldId: HuntingControlEventField) {
        guard let attachment = controller.getAttachment(field: fieldId) else {
            print("Failed to obtain attachment, cannot remove")
            return
        }

        let alertController = MDCAlertController(
            title: "AreYouSure".localized(),
            message: String(format: "HuntingControlDeleteAttachmentQuestion".localized(), attachment.fileName)
        )
        alertController.addAction(MDCAlertAction(title: "Yes".localized()) { [weak self] _ in
            guard let self = self else { return }

            self.attachmentOpenHelper.cancelAttachmentDownload(attachment: attachment)
            self.controller.eventDispatchers.attachmentActionEventDispatcher.dispatchEvent(fieldId: fieldId)
        })
        alertController.addAction(MDCAlertAction(title: "No".localized()))


        present(alertController, animated: true)
    }

    // MARK: KeyboardHandlerDelegate

    func getBottommostVisibleViewWhileKeyboardVisible() -> UIView? {
        tableView
    }
}

fileprivate let IMAGE_DATE_FORMATTER: DateFormatter = {
    DateFormatter(safeLocale: ()).apply({ formatter in
        formatter.dateFormat = "yyyyMMdd_HHmmss"
    })
}()
