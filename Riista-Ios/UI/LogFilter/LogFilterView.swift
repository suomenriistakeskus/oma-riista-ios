import Foundation
import DropDown
import MaterialComponents
import SnapKit

protocol LogFilterDelegate {
    func onFilterTypeSelected(selectedType: LogFilterView.FilteredType, oldType: LogFilterView.FilteredType)
    func onFilterSeasonSelected(seasonStartYear: Int)
    func onFilterSpeciesSelected(speciesCodes: [Int])
    func onFilterCategorySelected(categoryCode: Int)
    func onFilterPointOfInterestListClicked()

    func presentSpeciesSelect()
}

class LogFilterView: UIView {
    // 15 seems to be the largest that allows multiline labels for species
    private static let fontSize: CGFloat = 15

    var delegate: LogFilterDelegate?

    private var enableSrva = false
    var enablePointsOfInterest: Bool = false

    enum FilteredType {
        case harvest, observation, srva, pointsOfInterest

        func toRiistaEntryType() -> RiistaEntryType? {
            switch self {
            case .harvest:          return RiistaEntryTypeHarvest
            case .observation:      return RiistaEntryTypeObservation
            case .srva:             return RiistaEntryTypeSrva
            case .pointsOfInterest: return nil
            }
        }
    }

    var filteredType: FilteredType = .harvest {
        didSet {
            filteredTypeUpdateTimeStamp = Date()
            onFilteredTypeChanged(type: filteredType)
        }
    }

    private(set) var filteredTypeUpdateTimeStamp: Date = Date(timeIntervalSince1970: 0)

    // convenience access for old code
    var logType: RiistaEntryType? {
        get {
            filteredType.toRiistaEntryType()
        }
        set(value) {
            if let newFilteredType = value?.toFilteredType() {
                filteredType = newFilteredType
            }
        }
    }

    var seasonStartYear: Int? {
        didSet {
            onSeasonStartYearChanged()
        }
    }


    private lazy var topContainer: UIStackView = {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill

        container.addView(buttonsContainer)
        container.addView(clearSelectionsArea)
        return container
    }()

    private lazy var buttonsContainer: UIStackView = {
        let container = UIStackView()
        container.axis = .horizontal
        container.distribution = .fillEqually
        container.alignment = .fill

        container.addView(typeButton)
        container.addView(seasonsButton)
        container.addView(speciesButton)
        container.addView(listPoisButton)

        container.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }
        return container
    }()

    private lazy var typeButton: CustomizableMaterialButton = {
        let button = createDropdownButton().withSeparatorAtTrailing()
        button.onClicked = {
            self.onTypeClicked()
        }
        return button
    }()

    private lazy var seasonsButton: CustomizableMaterialButton = {
        let button = createDropdownButton().withSeparatorAtTrailing()
        button.onClicked = {
            self.onSeasonsButtonClicked()
        }
        return button
    }()

    private lazy var speciesButton: CustomizableMaterialButton = {
        let button = CustomizableMaterialButton(config: BUTTON_CONFIG)
        button.updateLayoutMargins(horizontal: 4, vertical: 2)
        button.onClicked = {
            self.onSpeciesButtonClicked()
        }
        return button
    }()

    private lazy var listPoisButton: MaterialButton = {
        let button = MaterialButton()
        AppTheme.shared.setupTextButtonTheme(button: button)
        button.backgroundColor = .white

        button.setTitleFont(UIFont.appFont(fontSize: Self.fontSize), for: .normal)
        button.setTitleColor(UIColor.applicationColor(TextPrimary), for: .normal)
        button.isUppercaseTitle = false
        button.setImage(UIImage(named: "list_white")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImageTintColor(UIColor.applicationColor(Primary), for: .normal)

        button.isHidden = (filteredType != .pointsOfInterest)
        button.onClicked = {
            self.onListPoisClicked()
        }
        return button
    }()

    private lazy var clearSelectionsArea: MaterialButton = {
        let container = MaterialButtonWithRoundedCorners()
        AppTheme.shared.setupTextButtonTheme(button: container)
        container.cornerRadius = 0
        container.roundedCorners = CACornerMask.allCorners()
        container.backgroundColor = UIColor.applicationColor(GreyLight)

        container.onClicked = {
            self.onClearSelectionsClicked()
        }

        let closeIndicator = UIImageView()
        closeIndicator.contentMode = .center
        closeIndicator.image = UIImage(named: "cross")

        container.addSubview(clearSelectionsLabel)
        container.addSubview(closeIndicator)

        clearSelectionsLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(closeIndicator.snp.leading).offset(-8)
        }

        closeIndicator.snp.makeConstraints { make in
            make.width.equalTo(closeIndicator.snp.height)
            make.centerY.height.equalToSuperview()
            make.trailing.equalToSuperview().inset(8)
        }

        container.snp.makeConstraints { make in
            make.height.equalTo(30)
        }

        return container
    }()

    private lazy var clearSelectionsLabel: UILabel = UILabel().configure(fontSize: Self.fontSize)

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func setupView() {
        backgroundColor = UIColor.applicationColor(ViewBackground)

        addSubview(topContainer)
        topContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setupUserRelatedData()
        clearSpeciesFilter()
    }

    func setupUserRelatedData() {
        enableSrva = RiistaSettings.userInfo()?.enableSrva.boolValue ?? false
    }

    func updateTexts() {
        clearSelectionsLabel.text = "FilterClearSpeciesFilter".localized()
        typeButton.setTitle(filteredType.localizationKey.localized(), for: .normal)
        listPoisButton.setTitle("PointsOfInterestListButtonTitle".localized(), for: .normal)
    }

    func setSelectedSpecies(speciesCodes: [Int]) {
        let speciesButtonText: String
        switch speciesCodes.count {
        case 0:
            speciesButtonText = "ChooseSpecies".localized()
        case 1:
            if (speciesCodes[0] == AppConstants.SrvaOtherCode) {
                speciesButtonText = "SrvaOtherSpeciesDescription".localized()
            }
            else {
                let species = RiistaGameDatabase.sharedInstance()?.species(byId: speciesCodes[0])
                speciesButtonText = RiistaUtils.name(withPreferredLanguage: species?.name)
            }

            showSpeciesClear()
        default:
            speciesButtonText = "\(speciesCodes.count) " + RiistaBridgingUtils.RiistaLocalizedString(forkey: "FilterSelectedSpeciesCount")

            showSpeciesClear()
        }

        speciesButton.setTitle(speciesButtonText, for: .normal)
    }

    func setSelectedCategory(categoryCode: Int) {
        let category = RiistaGameDatabase.sharedInstance()?.categories[categoryCode] as! RiistaSpeciesCategory
        speciesButton.setTitle(RiistaUtils.name(withPreferredLanguage: category.name), for: .normal)

        showSpeciesClear()
    }

    func refreshFilteredSpecies(selectedCategory: Int, selectedSpecies: [Int]) {
        if (selectedCategory < 0 && selectedSpecies.count == 0) {
            clearSelectionsArea.isHidden = true
        }

        if selectedCategory >= 0 {
            setSelectedCategory(categoryCode: selectedCategory)
        } else {
            setSelectedSpecies(speciesCodes: selectedSpecies)
        }
    }

    func showSpeciesClear() {
        self.clearSelectionsArea.isHidden = false
    }

    func clearSpeciesFilter() {
        UIView.animate(withDuration: AppConstants.Animations.durationShort) {
            self.clearSelectionsArea.isHidden = true
        }

        setSelectedSpecies(speciesCodes: [])
        delegate?.onFilterSpeciesSelected(speciesCodes: [])
    }

    private func onTypeClicked() {
        let dropDown = DropDown()

        var filteredTypes: [FilteredType] = [.harvest, .observation]
        if (enableSrva) {
            filteredTypes.append(.srva)
        }
        if (enablePointsOfInterest) {
            filteredTypes.append(.pointsOfInterest)
        }

        dropDown.anchorView = typeButton
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y: typeButton.plainView.bounds.height)
        dropDown.dataSource = filteredTypes.map { type in
            type.localizationKey.localized()
        }
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.onFilteredTypeSelected(filteredTypes[index])
        }

        dropDown.show()
    }

    private func onFilteredTypeSelected(_ type: FilteredType) {
        let oldType = filteredType
        filteredType = type
        delegate?.onFilterTypeSelected(selectedType: type, oldType: oldType)
    }

    private func onSeasonsButtonClicked() {
        let years: [Int]
        switch filteredType {
        case .harvest:
            years = RiistaGameDatabase.sharedInstance()?.eventYears(DiaryEntryTypeHarvest)
                .compactMap { eventYear in
                    (eventYear as? NSNumber)?.intValue
                } ?? []
        case .observation:
            years = RiistaGameDatabase.sharedInstance()?.observationYears()
                .compactMap { eventYear in
                    (eventYear as? NSNumber)?.intValue
                } ?? []
        case .srva:
            years = RiistaGameDatabase.sharedInstance()?.eventYears(DiaryEntryTypeSrva)
                .compactMap { eventYear in
                    if let year = (eventYear as? NSNumber)?.intValue {
                        return year + 1
                    } else {
                        return nil
                    }
                } ?? []
        case .pointsOfInterest:
            print("How can seasons button be clicked while POI is selected?")
            return
        }
        let sortedYears = years.sorted(by: >)

        let dropDown = DropDown()
        dropDown.anchorView = seasonsButton
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y: seasonsButton.plainView.bounds.height)
        dropDown.dataSource = sortedYears.map { year in
            year.formatToSeasonsText(srva: filteredType == .srva)
        }

        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.onSeasonStartYearSelected(year: sortedYears[index])
        }

        dropDown.show()
    }

    private func onSeasonStartYearSelected(year: Int) {
        self.seasonStartYear = year
        self.delegate?.onFilterSeasonSelected(seasonStartYear: year)
    }

    private func onSpeciesButtonClicked() {
        delegate?.presentSpeciesSelect()
    }

    private func onClearSelectionsClicked() {
        clearSpeciesFilter()
    }

    private func onListPoisClicked() {
        delegate?.onFilterPointOfInterestListClicked()
    }

    func presentSpeciesSelect(navigationController: UINavigationController, delegate: LogFilterDelegate) {
        guard let storyBoard = navigationController.storyboard else {
            print("No storyboard, cannot present species select!")
            return
        }

        if (filteredType == .srva) {
            let destination = storyBoard.instantiateViewController(withIdentifier: "FilterSpeciesController") as! FilterSpeciesViewController
            destination.delegate = delegate
            destination.isSrva = true

            navigationController.pushViewController(destination, animated: true)
        }
        else {
            let destination = storyBoard.instantiateViewController(withIdentifier: "FilterCategoryController") as! FilterCategoryViewController
            destination.delegate = delegate

            navigationController.pushViewController(destination, animated: true)
        }
    }

    private func onFilteredTypeChanged(type: FilteredType) {
        typeButton.setTitle(type.localizationKey.localized(), for: .normal)

        let viewHiddenStatuses: [UIView : Bool]
        switch type {
        case .harvest, .observation, .srva:
            viewHiddenStatuses = [
                seasonsButton : false,
                speciesButton : false,
                listPoisButton : true
            ]
        case .pointsOfInterest:
            viewHiddenStatuses = [
                seasonsButton : true,
                speciesButton : true,
                listPoisButton : false
            ]
        }

        UIView.animate(withDuration: AppConstants.Animations.durationShort) {
            viewHiddenStatuses.forEach { hiddenStatus in
                if (hiddenStatus.key.isHidden != hiddenStatus.value) {
                    // stackview breaks if hiding multiple times when using animations:
                    // https://github.com/nkukushkin/StackView-Hiding-With-Animation-Bug-Example
                    hiddenStatus.key.isHidden = hiddenStatus.value
                }
            }
        }
    }

    private func onSeasonStartYearChanged() {
        let seasonButtonText = seasonStartYear?.formatToSeasonsText(srva: filteredType == .srva) ?? "-"
        seasonsButton.setTitle(seasonButtonText, for: .normal)
    }

    private func createDropdownButton() -> CustomizableMaterialButton {
        let button = CustomizableMaterialButton(config: DROPDOWN_BUTTON_CONFIG)
        button.bottomIcon = UIImage(named: "arrow_drop_down")
        button.updateLayoutMargins(horizontal: 4, vertical: 2)
        return button
    }
}

fileprivate extension LogFilterView.FilteredType {
    var localizationKey: String {
        switch self {
        case .harvest:          return "Harvest"
        case .observation:      return "Observation"
        case .srva:             return "Srva"
        case .pointsOfInterest: return "PointsOfInterest"
        }
    }
}

fileprivate extension RiistaEntryType {
    func toFilteredType() -> LogFilterView.FilteredType {
        switch self {
        case RiistaEntryTypeHarvest:        return .harvest
        case RiistaEntryTypeObservation:    return .observation
        case RiistaEntryTypeSrva:           return .srva
        default:
            fatalError("Unexpected entry type \(self)")
        }
    }
}

fileprivate extension Int {
    func formatToSeasonsText(srva: Bool) -> String {
        if (srva) {
            return String(format: "%d", self)
        } else {
            return String(format: "%d-%d", self, self+1)
        }
    }
}


fileprivate let BUTTON_CONFIG = CustomizableMaterialButtonConfig { config in
    config.titleTextTransform = { titleText in
        // don't transform in any way
        titleText
    }
    config.titleNumberOfLines = 2
}

fileprivate let DROPDOWN_BUTTON_CONFIG = CustomizableMaterialButtonConfig { config in
    config.titleTextTransform = { titleText in
        // don't transform in any way
        titleText
    }
    config.titleNumberOfLines = 1
    config.verticalSpacing = 4
    config.bottomIconSize = nil // use whatever the icon size we have
}
