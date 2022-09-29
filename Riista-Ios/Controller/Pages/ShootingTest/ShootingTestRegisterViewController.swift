import UIKit
import AVFoundation
import QRCodeReader
import Toast_Swift
import MaterialComponents.MaterialDialogs

class ShootingTestRegisterViewController: UIViewController, UITextFieldDelegate, QRCodeReaderViewControllerDelegate, ShootingTestCheckboxDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var inputTextView: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var readQrCodeButton: UIButton!
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
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var addButton: UIButton!

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
        self.addParticipant(hunterNumber: (self.searchResult?.hunterNumber)!)
    }

    var searchResult: ShootingTestSearchPersonResult? = nil

    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr, .code39], captureDevicePosition: .back)
        }

        return QRCodeReaderViewController(builder: builder)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "refresh_white"),
            style: .plain,
            target: self,
            action: #selector(onRefreshClicked)
        )

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

        self.hideKeyboard()
        self.setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = "ShootingTestViewTitle".localized()
        self.resetSearchResult()
        self.refreshData()
    }

    func setupUI() {
        self.titleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterAddParticipant")
        self.promptLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterHunterNumber").uppercased()

        self.inputTextView.delegate = self

        Styles.styleButton(self.searchButton)
        Styles.styleButton(self.readQrCodeButton)
        self.readQrCodeButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterReadQr"), for: .normal)

        Styles.styleButton(self.addButton)
        Styles.styleNegativeButton(self.clearButton)
        self.clearButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ButtonClearTitle"), for: .normal)
        self.addButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterAddParticipant"), for: .normal)

        self.resultStateLabel.layer.cornerRadius = 4
        self.resultTestTypesLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterTestTypeTitle")

        self.resultTestBearView.setTitle(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBear"))
        self.resultTestMooseView.setTitle(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeMoose"))
        self.resultTestRoeDeerView.setTitle(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeRoeDeer"))
        self.resultTestBowView.setTitle(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBow"))
    }

    private func refreshSearchResult(item: ShootingTestSearchPersonResult) {
        self.inputTextView.isEnabled = false
        self.searchButton.isEnabled = false

        self.readQrCodeButton.isEnabled = false
        self.qrButtonHeight.constant = 0

        self.resultNameLabel.text = String(format: "%@ %@", item.lastName!, item.firstName!)
        self.resultNumberLabel.text = item.hunterNumber
        self.resultDateOfBirthLabel.text = ShootingTestUtil.serverDateStringToDisplayDate(serverDate: item.dateOfBirth!)

        switch item.registrationStatus! {
        case ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_IN_PROGRESS:
            self.resultStateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterUserAlreadyRegistered")
            self.resultStateLabel.isHidden = false
            self.resultStateView.isHidden = false
            self.addButton.isEnabled = false
            break
        case ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_COMPLETED:
            self.resultStateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterUserAlreadyCompleted")
            self.resultStateLabel.isHidden = false
            self.resultStateView.isHidden = false
            self.addButton.isEnabled = true
            break
        case ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_HUNTING_PAYMENT_NOT_DONE:
            self.resultStateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterUserHuntingPaymentNotDone")
            self.resultStateLabel.isHidden = false
            self.resultStateView.isHidden = false
            self.addButton.isEnabled = true
            break
        case ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_OFFICIAL:
            self.resultStateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterUserAlreadyOfficial")
            self.resultStateLabel.isHidden = false
            self.resultStateView.isHidden = false
            self.addButton.isEnabled = false
            break
        case ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_HUNTING_BAN:
            self.resultStateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterUserHuntingBan")
            self.resultStateLabel.isHidden = false
            self.resultStateView.isHidden = false
            self.addButton.isEnabled = false
            break
        case ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_NOT_HUNTER:
            self.resultStateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterUserNotHunter")
            self.resultStateLabel.isHidden = false
            self.resultStateView.isHidden = false
            self.addButton.isEnabled = false
            break
        case ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_FOREIGN_HUNTER:
            self.resultStateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterUserForeignHunter")
            self.resultStateLabel.isHidden = false
            self.resultStateView.isHidden = false
            self.addButton.isEnabled = true
            break
        case ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_HUNTING_PAYMENT_DONE:
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

        self.resultTestBearView.setChecked(checked: (item.selectedShootingTestTypes?.bearTestIntended)!)
        self.resultTestMooseView.setChecked(checked: (item.selectedShootingTestTypes?.mooseTestIntended)!)
        self.resultTestRoeDeerView.setChecked(checked: (item.selectedShootingTestTypes?.roeDeerTestIntended)!)
        self.resultTestBowView.setChecked(checked: (item.selectedShootingTestTypes?.bowTestIntended)!)
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
        self.qrButtonHeight.constant = 50

        self.buttonView.isHidden = true
        self.resultView.isHidden = true
    }

    private func refreshAddButtonState() {
        self.addButton.isEnabled = self.searchResult != nil &&
            !(self.searchResult!.hunterNumber ?? "").isEmpty &&
            (ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_HUNTING_PAYMENT_DONE == self.searchResult?.registrationStatus ||
                ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_HUNTING_PAYMENT_NOT_DONE == self.searchResult?.registrationStatus ||
                ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_COMPLETED == self.searchResult?.registrationStatus ||
                ShootingTestSearchPersonResult.ClassConstants.REGISTRATION_STATUS_FOREIGN_HUNTER == self.searchResult?.registrationStatus) &&
            (self.resultTestMooseView.getChecked() || self.resultTestBearView.getChecked() || self.resultTestRoeDeerView.getChecked() || self.resultTestBowView.getChecked())
    }

    @objc private func onRefreshClicked() {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        refreshData()
    }

    func refreshData() {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        tabBarVc.fetchEvent() { (result:Any?, error:Error?) in
            self.navigationItem.rightBarButtonItem?.isEnabled = true

            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let event = try JSONDecoder().decode(ShootingTestCalendarEvent.self, from: json)

                    if (event.isOngoing()) {
                        self.inputTextView.isEnabled = true
                        self.searchButton.isEnabled = self.inputTextView.text?.count == 8
                        self.readQrCodeButton.isEnabled = true
                    }
                    else {
                        self.inputTextView.isEnabled = false
                        self.searchButton.isEnabled = false
                        self.readQrCodeButton.isEnabled = false
                    }
                }
                catch {
                    print("Failed to parse <ShootingTestCalendarEvent> item")
                }
            }
            else {
                print("fetchEvent failed: " + (error?.localizedDescription)!)
            }
        }
    }

    private func searchWithHunterNumber(input: String) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        ShootingTestManager.searchWithHuntingNumberForEvent(eventId: tabBarVc.eventId!,
                                                            hunterNumber: input)
        { (result:Any?, error:Error?) in
            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let item = try JSONDecoder().decode(ShootingTestSearchPersonResult.self, from: json)

                    self.searchResult = item
                    self.refreshSearchResult(item: item)
                }
                catch {
                    print("Failed to parse <ShootingTestSearchPersonResult> item")
                }
            }
            else {
                print("searchWithHuntingNumberForEvent failed: " + (error?.localizedDescription)!)
                self.navigationController?.view.makeToast(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterSearchNoResults"))
            }
        }
    }

    private func searchWithSsn(input: String) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController

        ShootingTestManager.searchWithSsnForEvent(eventId: tabBarVc.eventId!, ssn: input)
        { (result:Any?, error:Error?) in
            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let item = try JSONDecoder().decode(ShootingTestSearchPersonResult.self, from: json)

                    self.searchResult = item
                    self.refreshSearchResult(item: item)
                }
                catch {
                    print("Failed to parse <ShootingTestSearchPersonResult> item")
                }
            }
            else {
                print("searchWithHuntingNumberForEvent failed: " + (error?.localizedDescription)!)
                self.navigationController?.view.makeToast(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterSearchNoResults"))
            }
        }
    }

    private func addParticipant(hunterNumber: String) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        ShootingTestManager.addParticipantToEvent(eventId: tabBarVc.eventId!,
                                                  hunterNumber: hunterNumber,
                                                  bearTestIntended: self.resultTestBearView.getChecked(),
                                                  mooseTestIntended: self.resultTestMooseView.getChecked(),
                                                  roeDeerTestIntended: self.resultTestRoeDeerView.getChecked(),
                                                  bowTestIntended: self.resultTestBowView.getChecked())
        { (result:Any?, error:Error?) in
            if (error == nil) {
                self.resetSearchResult()
                self.refreshData()
            }
            else {
                print("addParticipantToEvent failed: " + (error?.localizedDescription)!)
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

        let pattern = "^.*;.*;.*;\\d*;(\\d{8});\\d*;\\d*;.*$"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: result.value, options: [], range: NSRange(location: 0, length: result.value.count))

        let ssnPattern = "^\\d{6}[A+-]\\d{3}[0-9A-FHJ-NPR-Y]$"
        let ssnRegEx = try! NSRegularExpression(pattern: ssnPattern, options: [])
        let ssnMatches = ssnRegEx.matches(in: result.value, options: [], range: NSRange(location: 0, length: result.value.count))

        if (matches.count > 0) {
            // Safe to assume only one match
            let match = matches.first
            let range = match?.range(at: 1)
            let matchString = result.value[Range(range!, in: result.value)!]

            let alert = MDCAlertController(title: nil,
                                           message: String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterSearchWithScannedHunterNumber"), matchString as CVarArg))
            alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK"),
                                           handler: { action in
                self.searchWithHunterNumber(input: String(matchString))
            }))
            alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "No"), handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else if (ssnMatches.count > 0) {
            let matchString = result.value

            let alert = MDCAlertController(title: nil,
                                           message: String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterSearchWithScannedSsn"), matchString))
            alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK"),
                                           handler: { action in
                                            self.searchWithSsn(input: matchString)
            }))
            alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "No"), handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            self.navigationController?.view.makeToast(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestRegisterReadQrFailed"))
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
