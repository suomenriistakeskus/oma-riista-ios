import Foundation
import UIKit
import DropDown
import MaterialComponents
import SnapKit
import RiistaCommon


class ViewHuntingControlEventViewController:
    BaseControllerWithViewModel<ViewHuntingControlEventViewModel, ViewHuntingControlEventController>,
    ProvidesNavigationController,
    EditHuntingControlEventViewControllerListener,
    AttachmentFieldStatusProvider {

    private let huntingControlEventTarget: RiistaCommon.HuntingControlEventTarget
    private lazy var attachmentOpenHelper: HuntingControlAttachmentOpenHelper = {
        HuntingControlAttachmentOpenHelper(parentViewController: self)
    }()

    private lazy var _controller: RiistaCommon.ViewHuntingControlEventController = {
        RiistaCommon.ViewHuntingControlEventController(
            huntingControlContext: RiistaSDK.shared.currentUserContext.huntingControlContext,
            huntingControlEventTarget: huntingControlEventTarget,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: ViewHuntingControlEventController {
        get {
            _controller
        }
    }

    private let tableViewController = DataFieldTableViewController<HuntingControlEventField>()

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

    init(huntingControlEventTarget: HuntingControlEventTarget) {
        self.huntingControlEventTarget = huntingControlEventTarget
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
            attachmentClickListener: onAttachmentClicked,
            attachmentStatusProvider: self
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        title = "HuntingControlViewPageTitle".localized()
        navigationItem.rightBarButtonItems = [editNavBarButton]
    }

    @objc func onEditButtonClicked() {
        let editControlled = EditHuntingControlEventViewController(huntingControlEventTarget: huntingControlEventTarget,
                                                                   listener: self)

        navigationController?.pushViewController(editControlled, animated: true)
    }

    private func updateEditButtonVisibility(canEdit: Bool) {
        editNavBarButton.isHidden = !canEdit
    }


    override func onViewModelLoaded(viewModel: ViewHuntingControlEventViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        updateEditButtonVisibility(canEdit: viewModel.canEditHuntingControlEvent)

        tableViewController.setDataFields(dataFields: viewModel.fields)
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

    // MARK: - EditHuntingControlEventViewController

    func onHuntingControlEventUpdated(eventTarget: HuntingControlEventTarget) {
        controllerHolder.shouldRefreshViewModel = true
        navigationController?.popViewController(animated: true)
    }
}
