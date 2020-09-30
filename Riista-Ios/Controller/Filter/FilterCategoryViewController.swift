import Foundation
import MaterialComponents

class FilterCategoryViewController: UIViewController {

    @IBOutlet weak var category1Title: UILabel!
    @IBOutlet weak var category2Title: UILabel!
    @IBOutlet weak var category3Title: UILabel!

    @IBOutlet weak var selectCategory1Button: MDCButton!
    @IBOutlet weak var selectCategory2Button: MDCButton!
    @IBOutlet weak var selectCategory3Button: MDCButton!

    @IBOutlet weak var openCategory1Button: MDCButton!
    @IBOutlet weak var openCategory2Button: MDCButton!
    @IBOutlet weak var openCategory3Button: MDCButton!

    var delegate: LogFilterDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let categories = RiistaGameDatabase.sharedInstance()?.categories as! [Int : RiistaSpeciesCategory]

        setupCategoryRow(catTitle: category1Title, selectButton: selectCategory1Button, openButton: openCategory1Button, catId: 1, category: categories[1]!)

        setupCategoryRow(catTitle: category2Title, selectButton: selectCategory2Button, openButton: openCategory2Button, catId: 2, category: categories[2]!)

        setupCategoryRow(catTitle: category3Title, selectButton: selectCategory3Button, openButton: openCategory3Button, catId: 3, category: categories[3]!)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.rightBarButtonItem = nil
    }

    private func setupCategoryRow(catTitle: UILabel, selectButton: MDCButton, openButton: MDCButton, catId: Int, category: RiistaSpeciesCategory) {
        let language = RiistaSettings.language()

        catTitle.text = category.name[language!] as? String

        selectButton.tag = catId
        selectButton.applyTextTheme(withScheme: AppTheme.shared.outlineButtonSchemeSmall())
        selectButton.titleLabel?.lineBreakMode = .byWordWrapping
        selectButton.titleLabel?.textAlignment = .center
        selectButton.titleEdgeInsets.left = 0
        selectButton.titleEdgeInsets.right = 0
        selectButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "FilterSelectCategoryTwoLine"), for: .normal)
        selectButton.addTarget(self, action: #selector(didTapSelectCategory), for: .touchUpInside)

        openButton.tag = catId
        openButton.applyTextTheme(withScheme: AppTheme.shared.outlineButtonSchemeSmall())
        openButton.titleLabel?.lineBreakMode = .byWordWrapping
        openButton.titleLabel?.textAlignment = .center
        selectButton.titleEdgeInsets.left = 0
        selectButton.titleEdgeInsets.right = 0
        openButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "FilterSelectSpecies"), for: .normal)
        openButton.addTarget(self, action: #selector(didTapOpenCategory), for: .touchUpInside)
    }

    @objc func didTapSelectCategory(sender: MDCButton) {
        let catId = sender.tag
        delegate?.onFilterCategorySelected(categoryCode: catId)

        self.navigationController?.popViewController(animated: true)
    }

    @objc func didTapOpenCategory(sender: MDCButton) {
        let catId = sender.tag

        let storyBoard = navigationController?.storyboard
        let destination = storyBoard?.instantiateViewController(withIdentifier: "FilterSpeciesController") as! FilterSpeciesViewController
        destination.delegate = delegate
        destination.categoryId = catId

        navigationController?.pushViewController(destination, animated: true)
    }
}
