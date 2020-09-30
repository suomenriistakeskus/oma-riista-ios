import Foundation
import DropDown
import MaterialComponents.MaterialButtons

@objc protocol LogFilterDelegate {
    func onFilterTypeSelected(type: RiistaEntryType)
    func onFilterSeasonSelected(seasonStartYear: Int)
    func onFilterSpeciesSelected(speciesCodes: [Int])
    func onFilterCategorySelected(categoryCode: Int)

    func presentSpeciesSelect()
}

@IBDesignable class LogFilterView: UIView {

    let nibName = "LogFilterView"

    @IBOutlet weak var contentView: UIView!

    @IBOutlet weak var typeView: UIView!
    @IBOutlet weak var typeLabel: UILabel!

    @IBOutlet weak var seasonView: UIView!
    @IBOutlet weak var seasonLabel: UILabel!

    @IBOutlet weak var speciesView: UIView!
    @IBOutlet weak var speciesLabel: UILabel!

    @IBOutlet weak var clearButton: UIView!
    @IBOutlet weak var clearLabel: UILabel!
    @IBOutlet weak var clearHeight: NSLayoutConstraint!

    @objc var delegate: LogFilterDelegate?
    var navController: UINavigationController?

    private var enableSrva = false

    var logType: RiistaEntryType? {
        didSet {
            switch logType {
            case RiistaEntryTypeHarvest:
                typeLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "Harvest")
            case RiistaEntryTypeObservation:
                typeLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "Observation")
            case RiistaEntryTypeSrva:
                typeLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "Srva")
            default:
                typeLabel.text = "-"
            }
        }
    }

    var seasonStartYear: Int? {
        didSet {
            switch logType {
            case RiistaEntryTypeHarvest:
                seasonLabel.text = String(format: "%d-%d", seasonStartYear!, seasonStartYear! + 1)
            case RiistaEntryTypeObservation:
                seasonLabel.text = String(format: "%d-%d", seasonStartYear!, seasonStartYear! + 1)
            case RiistaEntryTypeSrva:
                seasonLabel.text = String(format: "%d", seasonStartYear!)
            default:
                seasonLabel.text = "-"
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        xibSetup()

        setupView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()

        setupView()
    }

    func xibSetup() {
        contentView = loadViewFromNib()
        addSubview(contentView)

        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }

    func setupView() {
        updateTexts()

        setupUserRelatedData()
        clearSpeciesFilter()

        let typeTap = UITapGestureRecognizer.init(target: self, action: #selector(typeTapAction(_:)))
        typeView.addGestureRecognizer(typeTap)

        let seasonTap = UITapGestureRecognizer.init(target: self, action: #selector(seasonTapAction(_:)))
        seasonView.addGestureRecognizer(seasonTap)

        let speciesTap = UITapGestureRecognizer.init(target: self, action: #selector(speciesTapAction(_:)))
        speciesView.addGestureRecognizer(speciesTap)

        let clearTap = UITapGestureRecognizer.init(target: self, action: #selector(clearTapAction(_:)))
        clearButton.addGestureRecognizer(clearTap)
    }

    @objc func setupUserRelatedData() {
        enableSrva = RiistaSettings.userInfo()?.enableSrva.boolValue ?? false
    }

    @objc func updateTexts() {
        clearLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "FilterClearSpeciesFilter")
    }

    // Helper for Objective-C usage. Use property from Swift
    @objc func setLogType(type: RiistaEntryType) {
        logType = type
    }

    // Helper for Objective-C usage. Use property from Swift
    @objc func setSeasonStartYear(year: Int) {
        seasonStartYear = year
    }

    @objc func setSelectedSpecies(speciesCodes: [Int]) {
        if (speciesCodes.count == 0) {
            speciesLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ChooseSpecies")
        }
        else if (speciesCodes.count == 1) {
            if (speciesCodes[0] == AppConstants.SrvaOtherCode) {
                speciesLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "SrvaOtherSpeciesDescription")
            }
            else {
                let species = RiistaGameDatabase.sharedInstance()?.species(byId: speciesCodes[0])
                speciesLabel.text = RiistaUtils.name(withPreferredLanguage: species?.name)
            }

            showSpeciesClear()
        }
        else {
            speciesLabel.text = "\(speciesCodes.count) " + RiistaBridgingUtils.RiistaLocalizedString(forkey: "FilterSelectedSpeciesCount")

            showSpeciesClear()
        }
    }

    @objc func setSelectedCategory(categoryCode: Int) {
        let cat = RiistaGameDatabase.sharedInstance()?.categories[categoryCode] as! RiistaSpeciesCategory
        speciesLabel.text = RiistaUtils.name(withPreferredLanguage: cat.name)

        showSpeciesClear()
    }

    @objc func refreshFilteredSpecies(selectedCategory: Int, selectedSpecies: [Int]) {
        if (selectedCategory < 0 && selectedSpecies.count == 0) {
            clearButton.isHidden = true
            clearHeight.constant = 0.0
        }

        if selectedCategory >= 0 {
            setSelectedCategory(categoryCode: selectedCategory)
        }
        else {
            setSelectedSpecies(speciesCodes: selectedSpecies)
        }
    }

    func showSpeciesClear() {
        clearButton.isHidden = false
        clearHeight.constant = 30.0
    }

    func clearSpeciesFilter() {
        clearButton.isHidden = true
        clearHeight.constant = 0.0
        setSelectedSpecies(speciesCodes: [Int]())
        delegate?.onFilterSpeciesSelected(speciesCodes: [Int]())
    }

    @objc func typeTapAction(_ sender: UITapGestureRecognizer? = nil) {
        let dropDown = DropDown()
        dropDown.anchorView = typeView
        dropDown.dataSource = [RiistaBridgingUtils.RiistaLocalizedString(forkey: "Harvest"),
                               RiistaBridgingUtils.RiistaLocalizedString(forkey: "Observation")]
        if (enableSrva) {
            dropDown.dataSource.append(RiistaBridgingUtils.RiistaLocalizedString(forkey: "Srva"))
        }
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")

            switch index {
            case 0:
                self.logType = RiistaEntryTypeHarvest
                self.delegate?.onFilterTypeSelected(type: RiistaEntryTypeHarvest)
            case 1:
                self.logType = RiistaEntryTypeObservation
                self.delegate?.onFilterTypeSelected(type: RiistaEntryTypeObservation)
            case 2:
                self.logType = RiistaEntryTypeSrva
                self.delegate?.onFilterTypeSelected(type: RiistaEntryTypeSrva)
            default:
                print("Illegal log type index: \(index)")
                self.logType = nil
                break
            }
        }

        dropDown.show()
    }

    @objc func seasonTapAction(_ sender: UITapGestureRecognizer? = nil) {
        let dropDown = DropDown()
        dropDown.anchorView = seasonView

        switch logType {
        case RiistaEntryTypeHarvest:
            let years = RiistaGameDatabase.sharedInstance()?.eventYears(DiaryEntryTypeHarvest)
            dropDown.dataSource = seasonStartToText(years: years)
            dropDown.dataSource.sort(by: >)
        case RiistaEntryTypeObservation:
            let years = RiistaGameDatabase.sharedInstance()?.observationYears()
            dropDown.dataSource = seasonStartToText(years: years)
            dropDown.dataSource.sort(by: >)
        case RiistaEntryTypeSrva:
            let years = RiistaGameDatabase.sharedInstance()?.eventYears(DiaryEntryTypeSrva)

            var shiftedYears = [Int]()
            if (years != nil) {
                for item in years as! [Int] {
                    shiftedYears.append(item + 1)
                }
            }

            dropDown.dataSource = seasonStartToText(years: shiftedYears, srva: true)
            dropDown.dataSource.sort(by: >)
        default:
            dropDown.dataSource = []
        }

        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")

            self.seasonStartYear = Int(item.prefix(4))
            self.delegate?.onFilterSeasonSelected(seasonStartYear: self.seasonStartYear!)
        }

        dropDown.show()
    }

    private func seasonStartToText(years: [Any]?, srva: Bool = false) -> [String] {
        var result = [String]()

        if (years != nil) {
            for item in years! {
                let number = item as! NSNumber
                if srva {
                    result.append(String(format: "%d", number.intValue))
                } else {
                    result.append(String(format: "%d-%d", number.intValue, number.intValue + 1))
                }
            }
        }

        return result
    }

    @objc func speciesTapAction(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.presentSpeciesSelect()
    }

    @objc func clearTapAction(_ sender: UITapGestureRecognizer? = nil) {
        clearSpeciesFilter()
    }

    @objc func presentSpeciesSelect(navigationController: UINavigationController, delegate: LogFilterDelegate) {
        let storyBoard = navigationController.storyboard

        if (LogItemService.shared().selectedLogType == RiistaEntryTypeSrva) {
            let destination = storyBoard?.instantiateViewController(withIdentifier: "FilterSpeciesController") as! FilterSpeciesViewController
            destination.delegate = delegate
            destination.isSrva = true

            navigationController.pushViewController(destination, animated: true)
        }
        else {
            let destination = storyBoard?.instantiateViewController(withIdentifier: "FilterCategoryController") as! FilterCategoryViewController
            destination.delegate = delegate

            navigationController.pushViewController(destination, animated: true)
        }
    }
}
