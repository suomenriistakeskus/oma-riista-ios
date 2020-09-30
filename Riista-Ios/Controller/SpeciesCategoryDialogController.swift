import Foundation

import MaterialComponents.MaterialButtons

class SpeciesCategoryDialogController: UIViewController {

    @IBOutlet weak var dialogTitle: UILabel!
    @IBOutlet weak var category1Button: MDCButton!
    @IBOutlet weak var category2Button: MDCButton!
    @IBOutlet weak var category3Button: MDCButton!

    var containerScheme = MDCContainerScheme()

    @objc var completionHandler: ((_ categoryCode: Int) -> Void)!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        containerScheme.colorScheme = MDCSemanticColorScheme()
        containerScheme.typographyScheme = MDCTypographyScheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        category1Button.applyTextTheme(withScheme: AppTheme.shared.buttonContainerScheme())
        category2Button.applyTextTheme(withScheme: AppTheme.shared.buttonContainerScheme())
        category3Button.applyTextTheme(withScheme: AppTheme.shared.buttonContainerScheme())

        category1Button.isUppercaseTitle = false
        category2Button.isUppercaseTitle = false
        category3Button.isUppercaseTitle = false

        let categories = RiistaGameDatabase.sharedInstance()?.categories as! [Int : RiistaSpeciesCategory]
        let language = RiistaSettings.language()

        dialogTitle.text =  RiistaBridgingUtils.RiistaLocalizedString(forkey: "ChooseSpecies")
        category1Button.setTitle(categories[1]?.name[language!] as? String, for: .normal)
        category2Button.setTitle(categories[2]?.name[language!] as? String, for: .normal)
        category3Button.setTitle(categories[3]?.name[language!] as? String, for: .normal)

        category1Button.tag = 1
        category1Button.addTarget(self, action: #selector(onButtonTap(_:)), for: .touchUpInside)

        category2Button.tag = 2
        category2Button.addTarget(self, action: #selector(onButtonTap(_:)), for: .touchUpInside)

        category3Button.tag = 3
        category3Button.addTarget(self, action: #selector(onButtonTap(_:)), for: .touchUpInside)
    }

    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 400.0, height: 225.0)
        }
        set {
            super.preferredContentSize = newValue
        }
    }

    @objc func onButtonTap(_ sender: MDCButton?) {
        self.dismiss(animated: true) {
            self.completionHandler?(sender?.tag ?? -1)
        }
    }
}
