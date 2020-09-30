import Foundation
import MaterialComponents

class MyDetailsViewController: RiistaPageViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameTitle: UILabel!
    @IBOutlet weak var nameValue: UILabel!
    @IBOutlet weak var dateOfBirthTitle: UILabel!
    @IBOutlet weak var dateOfBirthValue: UILabel!
    @IBOutlet weak var homePlaceTitle: UILabel!
    @IBOutlet weak var homePlaceValue: UILabel!
    @IBOutlet weak var addressTitle: UILabel!
    @IBOutlet weak var addressValue: UILabel!

    @IBOutlet weak var licenceButton: MDCButton!
    @IBOutlet weak var shootingTestButton: MDCButton!
    @IBOutlet weak var mhPermitsButton: MDCButton!
    @IBOutlet weak var occupationsButton: MDCButton!
    @IBOutlet weak var occupationsCard: MDCCard!

    override func viewDidLoad() {
        // display values using label font intentionally
        AppTheme.shared.setupLabelFont(label: nameTitle)
        AppTheme.shared.setupLabelFont(label: nameValue)
        AppTheme.shared.setupLabelFont(label: dateOfBirthTitle)
        AppTheme.shared.setupLabelFont(label: dateOfBirthValue)
        AppTheme.shared.setupLabelFont(label: homePlaceTitle)
        AppTheme.shared.setupLabelFont(label: homePlaceValue)
        AppTheme.shared.setupLabelFont(label: addressTitle)
        AppTheme.shared.setupLabelFont(label: addressValue)

        licenceButton.applyTextTheme(withScheme: AppTheme.shared.outlineButtonScheme())
        licenceButton.addTarget(self, action: #selector(licensePressed(sender:)), for: .touchUpInside)

        shootingTestButton.applyTextTheme(withScheme: AppTheme.shared.outlineButtonScheme())
        shootingTestButton.addTarget(self, action: #selector(shootingTestsPressed(sender:)), for: .touchUpInside)

        mhPermitsButton.applyTextTheme(withScheme: AppTheme.shared.outlineButtonScheme())
        mhPermitsButton.addTarget(self, action: #selector(mhPermitsPressed(sender:)), for: .touchUpInside)

        occupationsButton.applyTextTheme(withScheme: AppTheme.shared.outlineButtonScheme())
        occupationsButton.addTarget(self, action: #selector(occupationsPressed(sender:)), for: .touchUpInside)

        self.navigationController?.title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetails")
    }

    override func viewWillAppear(_ animated: Bool) {
        titleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsTitlePerson")
        nameTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsName")
        dateOfBirthTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsDateOfBirth")
        homePlaceTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsHomeMunicipality")
        addressTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsAddress")

        licenceButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsTitleHuntingLicense"), for: .normal)
        shootingTestButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsTitleShootingTests"), for: .normal)
        mhPermitsButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsMhPermitsTitle"), for: .normal)
        occupationsButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsAssignmentsTitle"), for: .normal)

        mhPermitsButton.setEnabled(MhPermitSync.anyPermitsExist(), animated: false)

        setupInformation(user: RiistaSettings.userInfo())
    }

    func setupInformation(user: UserInfo) {
        nameValue.text = String(format: "%@ %@", user.firstName, user.lastName)
        dateOfBirthValue.text = DatetimeUtil.dateToFormattedStringNoTime(date: user.birthDate)
        if let homeText = user.homeMunicipality[RiistaSettings.language()] {
            homePlaceValue.text = homeText as? String
        }
        else {
            homePlaceValue.text = user.homeMunicipality["fi"] as? String
        }
        if let userAddress = user.address {
            addressValue.text = String(format: "%@\n%@ %@\n%@",
                                       userAddress.streetAddress ?? "",
                                       userAddress.postalCode ?? "",
                                       userAddress.city ?? "",
                                       userAddress.country ?? "")
        }
        else {
            addressValue.text = nil
        }

        occupationsCard.isHidden = user.occupations.count < 1
    }

    override func refreshTabItem() {
        tabBarItem.title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MenuMyDetails")
    }
    
    @objc func licensePressed(sender: MDCButton) {
        let dest = self.storyboard?.instantiateViewController(withIdentifier:"HuntingLicenseController") as! HuntingLicenseViewController
        dest.user = RiistaSettings.userInfo()
        self.navigationController?.pushViewController(dest, animated: true)
    }

    @objc func shootingTestsPressed(sender: MDCButton) {
        let dest = self.storyboard?.instantiateViewController(withIdentifier:"ShootingTestsController") as! ShootingTestsViewController
        dest.user = RiistaSettings.userInfo()
        self.navigationController?.pushViewController(dest, animated: true)
    }

    @objc func mhPermitsPressed(sender: MDCButton) {
        let dest = self.storyboard?.instantiateViewController(withIdentifier:"MhPermitListController") as! MhPermitListViewController
        self.navigationController?.pushViewController(dest, animated: true)
    }

    @objc func occupationsPressed(sender: MDCButton) {
        let dest = self.storyboard?.instantiateViewController(withIdentifier:"OccupationsController") as! OccupationsViewController
        dest.user = RiistaSettings.userInfo()
        self.navigationController?.pushViewController(dest, animated: true)
    }
}
