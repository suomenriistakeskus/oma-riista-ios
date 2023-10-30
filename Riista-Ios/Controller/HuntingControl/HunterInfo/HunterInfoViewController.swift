import Foundation
import MaterialComponents
import SnapKit
import QRCodeReader
import RiistaCommon

class HunterInfoViewController :
    BaseControllerWithViewModel<HunterInfoViewModel, HunterInfoController>,
    ProvidesNavigationController,
    KeyboardHandlerDelegate,
    QRCodeReaderViewControllerDelegate,
    StartScanCellListener {

    private(set) var _controller = RiistaCommon.HunterInfoController(
        huntingControlContext: RiistaSDK.shared.huntingControlContext,
        languageProvider: CurrentLanguageProvider(),
        stringProvider: LocalizedStringProvider()
    )

    override var controller: HunterInfoController {
        get {
            _controller
        }
    }

    private let tableViewController = DataFieldTableViewController<HunterInfoField>()
    private var keyboardHandler: KeyboardHandler?

    private lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr, .code39], captureDevicePosition: .back)
        }

        return QRCodeReaderViewController(builder: builder)
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

    override func loadView() {
        super.loadView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

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
            intEventDispatcher: controller.intEventDispatcher,
            buttonClickHandler: { [weak self] fieldId in
                self?.handleButtonClick(fieldId: fieldId)
            }
        )
        tableViewController.addCellFactory(
            StartScanButtonCell.Factory(startScanCellListener: self)
        )

        title = "HuntingControlLandingPageTitle".localized()
    }

    override func viewWillAppear(_ animated: Bool) {
        controllerHolder.bindToViewModelLoadStatus()

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
    }

    private func handleButtonClick(fieldId: HunterInfoField) {
        switch (fieldId.type) {
        case .retryButton:
            controller.actionEventDispatcher.dispatchEvent(fieldId: fieldId)
            break
        case .resetButton:
            controller.actionEventDispatcher.dispatchEvent(fieldId: fieldId)
            break
        default:
            print("Unknown field clicked \(fieldId.type)")
        }
    }

    func onStartScanRequested() {
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }

    // MARK: QRCodeReaderViewController Delegate Methods

    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()

        dismiss(animated: true, completion: nil)

        let hunterNumberRegex = try! NSRegularExpression(pattern: ScanPattern.HunterNumberPattern, options: [])
        let hunterNumberMatches = hunterNumberRegex.matches(in: result.value, options: [], range: NSRange(location: 0, length: result.value.count))

        let ssnRegEx = try! NSRegularExpression(pattern: RemoteConfigurationManager.sharedInstance.ssnPattern(), options: [])
        let ssnMatches = ssnRegEx.matches(in: result.value, options: [], range: NSRange(location: 0, length: result.value.count))

        if (hunterNumberMatches.count > 0) {
            // Safe to assume only one match
            let match = hunterNumberMatches.first
            let range = match?.range(at: 1)
            let hunterNumber = String(result.value[Range(range!, in: result.value)!])
            controller.eventDispatcher.dispatchHunterNumber(number: hunterNumber)
        }
        else if (ssnMatches.count > 0) {
            let ssn = result.value
            controller.eventDispatcher.dispatchSsn(number: ssn)
        }
        else {
            self.navigationController?.view.makeToast(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterReadQrFailed"))
        }
    }

    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()

        dismiss(animated: true, completion: nil)
    }

    // MARK: KeyboardHandlerDelegate

    func getBottommostVisibleViewWhileKeyboardVisible() -> UIView? {
        tableView
    }
}
