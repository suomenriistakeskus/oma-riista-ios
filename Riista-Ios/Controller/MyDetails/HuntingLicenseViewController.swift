import Foundation

class HuntingLicenseViewController: UIViewController {

    @IBOutlet weak var nameTitle: UILabel!
    @IBOutlet weak var nameValue: UILabel!

    @IBOutlet weak var noLicenseView: UIView!
    @IBOutlet weak var noLicenseLabel: UILabel!

    @IBOutlet weak var huntingBanView: UIView!
    @IBOutlet weak var huntingBanTitle: UILabel!
    @IBOutlet weak var huntingBanValue: UILabel!

    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var hunterNumberTitle: UILabel!
    @IBOutlet weak var hunterNumberValue: UILabel!
    @IBOutlet weak var feePaidTitle: UILabel!
    @IBOutlet weak var feePaidValue: UILabel!
    @IBOutlet weak var rhyMembershipTitle: UILabel!
    @IBOutlet weak var rhyMembershipValue: UILabel!
    @IBOutlet weak var disclaimerLabel: UILabel!
    @IBOutlet weak var qrCodeImage: UIImageView!

    @objc var user: UserInfo?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateTitle()
        applyTheme()

        // user must be set during init
        refreshData(user: user!)
    }

    func updateTitle() {
        let navController = self.navigationController as? RiistaNavigationController
        navController?.changeTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsTitleHuntingLicense"))
    }

    func applyTheme() {
        AppTheme.shared.setupLabelFont(label: nameTitle)
        AppTheme.shared.setupLabelFont(label: nameValue)

        AppTheme.shared.setupLabelFont(label: huntingBanTitle)
        AppTheme.shared.setupLabelFont(label: huntingBanValue)

        AppTheme.shared.setupLabelFont(label: hunterNumberTitle)
        AppTheme.shared.setupLabelFont(label: hunterNumberValue)
        AppTheme.shared.setupLabelFont(label: feePaidTitle)
        AppTheme.shared.setupLabelFont(label: feePaidValue)
        AppTheme.shared.setupLabelFont(label: rhyMembershipTitle)
        AppTheme.shared.setupLabelFont(label: rhyMembershipValue)
        AppTheme.shared.setupLabelFont(label: disclaimerLabel)

        AppTheme.shared.setupLabelFont(label: noLicenseLabel)
    }

    func refreshData(user: UserInfo) {
        nameTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsName")
        noLicenseLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsNoValidLicense")
        huntingBanTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsHuntingBan")
        hunterNumberTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsHunterId")
        feePaidTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsPayment")
        rhyMembershipTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsMembership")
        disclaimerLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsInsurancePolicyText")

        nameValue.text = String(format: "%@ %@", user.firstName, user.lastName)

        if (user.huntingBanStart != nil || user.huntingBanEnd != nil) {
            // Hunting ban information is displayed instead of all other data if active
            huntingBanView.isHidden = false
            noLicenseView.isHidden = true
            detailsView.isHidden = true

            huntingBanValue.text = String(format: "%@ - %@",
                                          DatetimeUtil.dateToFormattedStringNoTime(date: user.huntingBanStart),
                                          DatetimeUtil.dateToFormattedStringNoTime(date: user.huntingBanEnd))
        }
        else if (user.huntingCardValidNow) {
            huntingBanView.isHidden = true
            noLicenseView.isHidden = true
            detailsView.isHidden = false

            // user.huntingCardValidNow does not necessarily mean that huntingCardEnd actually exist as according
            // to backend implementation it can also mean that hunting card is valid in the future (end validity not checked)
            // -> make sure dates exist before formatting
            let huntingCardStart = user.huntingCardStart != nil ? DatetimeUtil.dateToFormattedStringNoTime(date: user.huntingCardStart) : ""
            let huntingCardEnd = user.huntingCardEnd != nil ? DatetimeUtil.dateToFormattedStringNoTime(date: user.huntingCardEnd) : ""

            feePaidValue.text = String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsFeePaidFormat"),
                                       huntingCardStart, huntingCardEnd)

            if (user.rhy != nil) {
                if let rhyName = user.rhy.name[RiistaSettings.language()] as? String {
                    rhyMembershipValue.text = String(format: "%@ (%@)",
                    rhyName,
                    user.rhy.officialCode)
                }
                else {
                    rhyMembershipValue.text = String(format: "%@ (%@)",
                                                     user.rhy.name["fi"] as! String,
                                                     user.rhy.officialCode)
                }
            }
            else {
                rhyMembershipValue.text = nil
            }

            hunterNumberValue.text = user.hunterNumber

            // QR code should in theory be always present if hunting license is valid but in practise it may be missing
            qrCodeImage.image = user.qrCode != nil && !user.qrCode.isEmpty ?
                createQrImageFromText(qrString: user.qrCode, viewSize: qrCodeImage.frame.size) : nil

        }
        else {
            huntingBanView.isHidden = true
            noLicenseView.isHidden = false
            detailsView.isHidden = true
        }
    }

    func createQrImageFromText(qrString: String, viewSize: CGSize) -> UIImage {
        let stringData = qrString.data(using: String.Encoding.utf8)

        let qrFilter = CIFilter(name: "CIQRCodeGenerator")
        qrFilter?.setValue(stringData, forKey: "inputMessage")
        qrFilter?.setValue("H", forKey: "inputCorrectionLevel")

        var qrImage = qrFilter?.outputImage
        let scaleX = viewSize.width / (qrImage?.extent.size.width)!
        let scaleY = viewSize.height / (qrImage?.extent.size.height)!

        qrImage = qrImage?.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        return UIImage.init(ciImage: qrImage!, scale: UIScreen.main.scale, orientation: .up)
    }
}
