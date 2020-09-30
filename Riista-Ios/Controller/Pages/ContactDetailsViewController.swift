import Foundation
import MaterialComponents
import MessageUI

class ContactDetailsViewController: UIViewController, MFMailComposeViewControllerDelegate
{
    @IBOutlet weak var phoneSupportHeader: UILabel!
    @IBOutlet weak var phoneSupportCard: MDCCard!
    @IBOutlet weak var phoneSupportTitle: UILabel!
    @IBOutlet weak var phoneSupportValue: UILabel!

    @IBOutlet weak var emailSupportHeader: UILabel!
    @IBOutlet weak var emailSupportCard: MDCCard!
    @IBOutlet weak var emailSupportTitle: UILabel!
    @IBOutlet weak var emailSupportValue: UILabel!

    @IBOutlet weak var licenseSupportHeader: UILabel!
    @IBOutlet weak var licencePhoneCard: MDCCard!
    @IBOutlet weak var licencePhoneTitle: UILabel!
    @IBOutlet weak var licencePhoneValue: UILabel!

    @IBOutlet weak var licenceEmailCard: MDCCard!
    @IBOutlet weak var licenceEmailTitle: UILabel!
    @IBOutlet weak var licenceEmailValue: UILabel!

    static let customerServicePhoneNumber = "029 431 2111"
    static let customerSupportEmail = "oma@riista.fi"

    static let licenseSupportPhoneNumber = "029 431 2002"
    static let licenseSupportEmail = "metsastajarekisteri@innofactor.com"

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        RiistaLanguageRefresh;

        phoneSupportTitle.text = String.init(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "CustomerServiceTimesTemplate"), "12", "16")

        setupPhoneSupportCard()
        setupEmailSupportCard()
        setupLicenseSupportCards()

        pageSelected()
    }

    func setupView() {
        phoneSupportValue.text = ContactDetailsViewController.customerServicePhoneNumber;
        emailSupportValue.text = ContactDetailsViewController.customerSupportEmail;

        licencePhoneValue.text = ContactDetailsViewController.licenseSupportPhoneNumber;
        licenceEmailValue.text = ContactDetailsViewController.licenseSupportEmail;
    }

    func setupPhoneSupportCard() {
        phoneSupportHeader.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "CustomerService");

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(openCustomerSupportDialer(_:)))
        phoneSupportCard.addGestureRecognizer(tapRecognizer)
    }

    func setupEmailSupportCard() {
        emailSupportHeader.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "SupportAndFeedback");
        emailSupportTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "Email");

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(openEmailComposer(_:)))
        emailSupportCard.addGestureRecognizer(tapRecognizer)
    }

    func setupLicenseSupportCards() {
        licenseSupportHeader.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ContactLicenseIssuesTitle");
        licencePhoneTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "PhoneShort");

        let phoneTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(openLicenseSupportDialer(_:)))
        licencePhoneCard.addGestureRecognizer(phoneTapRecognizer)

        licenceEmailTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "Email");

        let emailTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(openLicenseEmailComposer(_:)))
        licenceEmailCard.addGestureRecognizer(emailTapRecognizer)
    }

    @objc func openCustomerSupportDialer(_ sender: UITapGestureRecognizer) {
        let alertController = MDCAlertController(title: nil,
                                                 message: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MakeCallMessage"))

        let callAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MakeCall")) { (action: MDCAlertAction) in
            self.callPhoneNumber(number: ContactDetailsViewController.customerServicePhoneNumber)
        }

        let cancelAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "CancelRemove")) { (action: MDCAlertAction) in
            // Do nothing
        }

        alertController.addAction(callAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }

    @objc func openLicenseSupportDialer(_ sender: UITapGestureRecognizer) {
        let alertController = MDCAlertController(title: nil,
                                                 message: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MakeLicenseCallMessage"))

        let callAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MakeCall")) { (action: MDCAlertAction) in
            self.callPhoneNumber(number: ContactDetailsViewController.licenseSupportPhoneNumber)
        }

        let cancelAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "CancelRemove")) { (action: MDCAlertAction) in
            // Do nothing
        }

        alertController.addAction(callAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }

    @objc func openEmailComposer(_ sender: UITapGestureRecognizer) {
        if (MFMailComposeViewController.canSendMail()) {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([ContactDetailsViewController.customerSupportEmail])

            let user = RiistaSettings.userInfo()
            let name = String(format: "%@ %@", user!.firstName, user!.lastName)

            let infoDictionary = Bundle.main.infoDictionary!
            let build = infoDictionary["CFBundleVersion"] as! String
            let device = UIDevice.current

            let emailBodyTemplate = String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "EmailTemplate"),
                                           name,
                                           user?.hunterNumber ?? "",
                                           build,
                                           device.systemVersion)

            mail.setSubject(RiistaBridgingUtils.RiistaLocalizedString(forkey: "EmailTitle"))
            mail.setMessageBody(emailBodyTemplate, isHTML: false)
            self.present(mail, animated: true, completion: nil)
        }
    }

    @objc func openLicenseEmailComposer(_ sender: UITapGestureRecognizer) {
        if (MFMailComposeViewController.canSendMail()) {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([ContactDetailsViewController.licenseSupportEmail])

            let user = RiistaSettings.userInfo()
            let name = String(format: "%@ %@", user!.firstName, user!.lastName)

            let emailBodyTemplate = String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "EmailLicenseTemplate"), name, user?.hunterNumber ?? "")

            mail.setSubject(RiistaBridgingUtils.RiistaLocalizedString(forkey: "EmailLicenseTitle"))
            mail.setMessageBody(emailBodyTemplate, isHTML: false)
            self.present(mail, animated: true, completion: nil)
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    func callPhoneNumber(number: String) {
        guard let url = URL(string: "tel://\(number.replacingOccurrences(of: " ", with: ""))") else { return }
        UIApplication.shared.open(url)
    }

    func refreshTabItem() {
        self.tabBarItem.title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MenuContactDetails")
    }

    func pageSelected() {
        navigationController?.title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ContactDetails")
    }
}
