import UIKit
import AVFoundation
import QRCodeReader
import Toast_Swift
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialDialogs
import RiistaCommon

class ShootingTestRegisterViewController: BaseViewController, UITextFieldDelegate, QRCodeReaderViewControllerDelegate, ShootingTestCheckboxDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var inputTextView: UITextField!
    @IBOutlet weak var searchButton: MDCButton!
    @IBOutlet weak var readQrCodeButton: MDCButton!
    @IBOutlet weak var resultView: UIView!
    @IBOutlet weak var resultNameLabel: UILabel!
    @IBOutlet weak var resultNumberLabel: UILabel!
    @IBOutlet weak var resultDateOfBirthLabel: UILabel!
    @IBOutlet weak var resultStateView: UIView!
    @IBOutlet weak var resultStateLabel: UILabel!
    @IBOutlet weak var resultTestTypesLabel: UILabel!
    @IBOutlet weak var resultTestBearView: ShootingTestCheckbox!
    @IBOutlet weak var resultTestMooseView: ShootingTestCheckbox!
    @IBOutlet weak var resultTestRoeDeerView: ShootingTestCheckbox!
    @IBOutlet weak var resultTestBowView: ShootingTestCheckbox!

    @IBOutlet weak var qrButtonHeight: NSLayoutConstraint!

    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var clearButton: MDCButton!
    @IBOutlet weak var addButton: MDCButton!

    @IBAction func searchButtonPressed(_ sender: UIButton) {
        self.inputTextView.resignFirstResponder()

        let input = inputTextView.text
        if (input?.count == 8 && Int(input!) != nil) {
            self.searchWithHunterNumber(input: input!)
        }
    }

    @IBAction func scanQrAction(_ sender: UIButton) {
        readerVC.delegate = self

        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }

    @IBAction func clearButtonPressed(_ sender: UIButton) {
        self.inputTextView.text = ""
        self.resetSearchResult()
    }

    @IBAction func saveButtonPressed(_ sender: UIButton) {
        guard let hunterNumber = self.searchResult?.hunterNumber else {
            return
        }

        self.addParticipant(hunterNumber: hunterNumber)
    }

    var searchResult: CommonShootingTestPerson? = nil

    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr, .code39], captureDevicePosition: .back)
        }

        return QRCodeReaderViewController(builder: builder)
    }()

    private var keyboardHandler: KeyboardHandler?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "refresh_white"),
            style: .plain,
            target: self,
            action: #selector(onRefreshClicked)
        )

        inputTextView.inputAccessoryView = KeyboardToolBar().hideKeyboardOnDone(editView: inputTextView)
        inputTextView.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        resultTestMooseView.delegate = self
        resultTestBearView.delegate = self
        resultTestRoeDeerView.delegate = self
        resultTestBowView.delegate = self

        var style = ToastStyle()
        style.messageColor = UIColor.black
        style.backgroundColor =  UIColor.white.withAlphaComponent(0.9)
        style.displayShadow = true
        ToastManager.shared.style = style

        // No need to adjust content upwards/downwards when keyboard is opened / closed
        // -> also no need for delegate nor listening of keyboard events
        keyboardHandler = KeyboardHandler(view: view, contentMovement: .none)

        self.setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = "ShootingTestViewTitle".localized()
        self.resetSearchResult()
        self.refreshData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Explicitly don't hide keyboard as this was the behaviour before transitioning
        // to using KeyboardHandler. This allows navigating to other tabs and returning
        // to this tab without having to click hunter number field again
        // keyboardHandler?.hideKeyboard()

        super.viewWillDisappear(animated)
    }

    func setupUI() {
        self.titleLabel.text = "ShootingTestRegisterAddParticipant".localized()
        self.promptLabel.text = "ShootingTestRegisterHunterNumber".localized().uppercased()

        self.inputTextView.delegate = self

        self.searchButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        self.readQrCodeButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        self.readQrCodeButton.isUppercaseTitle = false
        self.readQrCodeButton.setTitle("ShootingTestRegisterReadQr".localized(), for: .normal)

        self.addButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        self.addButton.isUppercaseTitle = false
        self.clearButton.applyOutlinedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        self.clearButton.isUppercaseTitle = false
        self.clearButton.setTitle("ButtonClearTitle".localized(), for: .normal)
        self.addButton.setTitle("ShootingTestRegisterAddParticipant".localized(), for: .normal)

        self.resultStateLabel.layer.cornerRadius = 4
        self.resultTestTypesLabel.text = "ShootingTestRegisterTestTypeTitle".localized()

        self.resultTestBearView.setTitle(text: "ShootingTestTypeBear".localized())
        self.resultTestMooseView.setTitle(text: "ShootingTestTypeMoose".localized())
        self.resultTestRoeDeerView.setTitle(text: "ShootingTestTypeRoeDeer".localized())
        self.resultTestBowView.setTitle(text: "ShootingTestTypeBow".localized())
    }

    private func refreshSearchResult(person: CommonShootingTestPerson) {
        self.inputTextView.isEnabled = false
        self.searchButton.isEnabled = false

        self.readQrCodeButton.isEnabled = false
        self.readQrCodeButton.isHidden = true
        self.qrButtonHeight.constant = 0

        self.resultNameLabel.text = String(format: "%@ %@",
                                           person.lastName ?? "",
                                           person.firstName ?? "")
        self.resultNumberLabel.text = person.hunterNumber
        self.resultDateOfBirthLabel.text = person.dateOfBirth?.toFoundationDate().formatDateOnly() ?? ""

        if let registrationStatus = person.registrationStatus.value {
            switch registrationStatus {
            case ShootingTestRegistrationStatus.inProgress:
                self.resultStateLabel.text = "ShootingTestRegisterUserAlreadyRegistered".localized()
                self.resultStateLabel.isHidden = false
                self.resultStateView.isHidden = false
                self.addButton.isEnabled = false
                break
            case ShootingTestRegistrationStatus.completed:
                self.resultStateLabel.text = "ShootingTestRegisterUserAlreadyCompleted".localized()
                self.resultStateLabel.isHidden = false
                self.resultStateView.isHidden = false
                self.addButton.isEnabled = true
                break
            case ShootingTestRegistrationStatus.huntingPaymentNotDone:
                self.resultStateLabel.text = "ShootingTestRegisterUserHuntingPaymentNotDone".localized()
                self.resultStateLabel.isHidden = false
                self.resultStateView.isHidden = false
                self.addButton.isEnabled = true
                break
            case ShootingTestRegistrationStatus.disqualifiedAsOfficial:
                self.resultStateLabel.text = "ShootingTestRegisterUserAlreadyOfficial".localized()
                self.resultStateLabel.isHidden = false
                self.resultStateView.isHidden = false
                self.addButton.isEnabled = false
                break
            case ShootingTestRegistrationStatus.huntingBan:
                self.resultStateLabel.text = "ShootingTestRegisterUserHuntingBan".localized()
                self.resultStateLabel.isHidden = false
                self.resultStateView.isHidden = false
                self.addButton.isEnabled = false
                break
            case ShootingTestRegistrationStatus.noHunterNumber:
                self.resultStateLabel.text = "ShootingTestRegisterUserNotHunter".localized()
                self.resultStateLabel.isHidden = false
                self.resultStateView.isHidden = false
                self.addButton.isEnabled = false
                break
            case ShootingTestRegistrationStatus.foreignHunter:
                self.resultStateLabel.text = "ShootingTestRegisterUserForeignHunter".localized()
                self.resultStateLabel.isHidden = false
                self.resultStateView.isHidden = false
                self.addButton.isEnabled = true
                break
            case ShootingTestRegistrationStatus.huntingPaymentDone:
                self.resultStateLabel.text = ""
                self.resultStateLabel.isHidden = true
                self.resultStateView.isHidden = true
                self.addButton.isEnabled = true
                break
            default:
                self.resultStateLabel.text = ""
                self.resultStateLabel.isHidden = true
                self.resultStateView.isHidden = true
                self.addButton.isEnabled = false
                break
            }
        } else {
            self.resultStateLabel.text = ""
            self.resultStateLabel.isHidden = true
            self.resultStateView.isHidden = true
            self.addButton.isEnabled = false
        }


        self.resultTestBearView.setChecked(checked: person.selectedShootingTestTypes.bearTestIntended)
        self.resultTestMooseView.setChecked(checked: person.selectedShootingTestTypes.mooseTestIntended)
        self.resultTestRoeDeerView.setChecked(checked: person.selectedShootingTestTypes.roeDeerTestIntended)
        self.resultTestBowView.setChecked(checked: person.selectedShootingTestTypes.bowTestIntended)
        self.refreshAddButtonState()

        self.resultView.isHidden = false
        buttonView.isHidden = false
    }

    private func resetSearchResult() {
        self.inputTextView.isEnabled = true
        self.resultNameLabel.text = nil
        self.resultNumberLabel.text = nil
        self.resultDateOfBirthLabel.text = nil

        self.resultStateLabel.text = nil
        self.resultStateLabel.isHidden = true
        self.resultStateView.isHidden = true

        self.resultTestBearView.setChecked(checked: false)
        self.resultTestMooseView.setChecked(checked: false)
        self.resultTestRoeDeerView.setChecked(checked: false)
        self.resultTestBowView.setChecked(checked: false)

        self.inputTextView.text = ""
        self.searchButton.isEnabled = false
        self.readQrCodeButton.isEnabled = true
        self.readQrCodeButton.isHidden = false
        self.qrButtonHeight.constant = 50

        self.buttonView.isHidden = true
        self.resultView.isHidden = true
    }

    private func refreshAddButtonState() {
        guard let person = self.searchResult else {
            self.addButton.isEnabled = false
            return
        }

        let invalidHunterNumber = (person.hunterNumber ?? "").isEmpty
        let testSelected =
            self.resultTestMooseView.getChecked() ||
            self.resultTestBearView.getChecked() ||
            self.resultTestRoeDeerView.getChecked() ||
            self.resultTestBowView.getChecked()

        let personQualifies =
            person.registrationStatus.value == ShootingTestRegistrationStatus.huntingPaymentDone ||
            person.registrationStatus.value == ShootingTestRegistrationStatus.huntingPaymentNotDone ||
            person.registrationStatus.value == ShootingTestRegistrationStatus.completed ||
            person.registrationStatus.value == ShootingTestRegistrationStatus.foreignHunter


        self.addButton.isEnabled = !invalidHunterNumber && personQualifies && testSelected
    }

    @objc private func onRefreshClicked() {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        refreshData()
    }

    func refreshData() {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        tabBarVc.fetchEvent() { [weak self] shootingTestEvent, _ in
            guard let self = self else { return }

            self.navigationItem.rightBarButtonItem?.isEnabled = true

            if (shootingTestEvent?.ongoing == true) {
                self.inputTextView.isEnabled = true
                self.searchButton.isEnabled = self.inputTextView.text?.count == 8
                self.readQrCodeButton.isEnabled = true
            } else {
                self.inputTextView.isEnabled = false
                self.searchButton.isEnabled = false
                self.readQrCodeButton.isEnabled = false
            }
        }
    }

    private func searchWithHunterNumber(input: String) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        tabBarVc.shootingTestManager.searchWithHuntingNumberForEvent(
            hunterNumber: input
        ) { [weak self] person, error in
            guard let self = self else { return }

            if let person = person {
                self.searchResult = person
                self.refreshSearchResult(person: person)
            } else {
                print("searchWithHunterNumber failed: \(error?.localizedDescription ?? String(describing: error))")
                self.navigationController?.view.makeToast("ShootingTestRegisterSearchNoResults".localized())
            }
        }
    }

    private func searchWithSsn(input: String) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController

        tabBarVc.shootingTestManager.searchWithSsnForEvent(
            ssn: input
        ) { [weak self] person, error in
            guard let self = self else { return }

            if let person = person {
                self.searchResult = person
                self.refreshSearchResult(person: person)
            } else {
                print("searchWithSsn failed: \(error?.localizedDescription ?? String(describing: error))")
                self.navigationController?.view.makeToast("ShootingTestRegisterSearchNoResults".localized())
            }
        }
    }

    private func addParticipant(hunterNumber: String) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        tabBarVc.shootingTestManager.addParticipantToEvent(
            hunterNumber: hunterNumber,
            bearTestIntended: self.resultTestBearView.getChecked(),
            mooseTestIntended: self.resultTestMooseView.getChecked(),
            roeDeerTestIntended: self.resultTestRoeDeerView.getChecked(),
            bowTestIntended: self.resultTestBowView.getChecked()
        ) { success, error in
            if (success) {
                self.resetSearchResult()
                self.refreshData()
            } else {
                print("addParticipant failed: \(error?.localizedDescription ?? String(describing: error))")
            }
        }
    }

    // MARK: UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // limit length
        let currentCharacterCount = textField.text?.count ?? 0
        if (range.length + range.location > currentCharacterCount){
            return false
        }
        let newLength = currentCharacterCount + string.count - range.length

        // limit to digits only
        let aSet = NSCharacterSet(charactersIn:"0123456789").inverted
        let compSepByCharInSet = string.components(separatedBy: aSet)
        let numberFiltered = compSepByCharInSet.joined(separator: "")

        return newLength <= 8 && string == numberFiltered
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        self.searchButton.isEnabled = textField.text?.count == 8
    }

    // MARK: QRCodeReaderViewController Delegate Methods

    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()

        dismiss(animated: true, completion: nil)

        let regex = try! NSRegularExpression(pattern: ScanPattern.HunterNumberPattern, options: [])
        let matches = regex.matches(in: result.value, options: [], range: NSRange(location: 0, length: result.value.count))

        let ssnRegEx = try! NSRegularExpression(pattern: RemoteConfigurationManager.sharedInstance.ssnPattern(), options: [])
        let ssnMatches = ssnRegEx.matches(in: result.value, options: [], range: NSRange(location: 0, length: result.value.count))

        if (matches.count > 0) {
            // Safe to assume only one match
            let match = matches.first
            let range = match?.range(at: 1)
            let matchString = result.value[Range(range!, in: result.value)!]

            let alert = MDCAlertController(title: nil,
                                           message: String(format: "ShootingTestRegisterSearchWithScannedHunterNumber".localized(), matchString as CVarArg))
            alert.addAction(MDCAlertAction(title: "OK".localized(),
                                           handler: { action in
                self.searchWithHunterNumber(input: String(matchString))
            }))
            alert.addAction(MDCAlertAction(title: "No".localized(), handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else if (ssnMatches.count > 0) {
            let matchString = result.value

            let alert = MDCAlertController(title: nil,
                                           message: String(format: "ShootingTestRegisterSearchWithScannedSsn".localized(), matchString))
            alert.addAction(MDCAlertAction(title: "OK".localized(),
                                           handler: { action in
                                            self.searchWithSsn(input: matchString)
            }))
            alert.addAction(MDCAlertAction(title: "No".localized(), handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            self.navigationController?.view.makeToast("ShootingTestRegisterReadQrFailed".localized())
        }
    }

    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()

        dismiss(animated: true, completion: nil)
    }

    // MARK: ShootingTestCheckboxDelegate

    func isCheckedChanged(_ checked: Bool) {
        refreshAddButtonState()
    }
}
