import Foundation
import DropDown
import MaterialComponents
import SnapKit
import RiistaCommon

protocol LogFilterViewDelegate {
    func presentSpeciesSelect()
    func onFilterPointOfInterestListClicked()
}

class LogFilterView: UIView, EntityFilterChangeListener, FilterCategoryViewControllerDelegate {
    private static var logger = AppLogger(for: LogFilterView.self, printTimeStamps: false)

    // 15 seems to be the largest that allows multiline labels for species
    private static let fontSize: CGFloat = 15

    var delegate: LogFilterViewDelegate?

    var changeListener: EntityFilterChangeRequestListener?

    private var enableSrva = false

    /**
     * Set the data source that will also act as a source when reacting to filter changes.
     */
    var dataSource: UnifiedEntityDataSource? {
        didSet {
            oldValue?.removeEntityFilterChangeListener(self)
            dataSource?.addEntityFilterChangeListener(self)
        }
    }

    var enabledFilteredTypes: [FilterableEntityType] {
        let supportedDataSourceTypes = dataSource?.supportedDataSourceTypes ?? []

        return supportedDataSourceTypes.filter { entityType in
            switch entityType {
            case .harvest:              return true
            case .observation:          return true
            case .srva:                 return enableSrva
            case .pointOfInterest:      return true
            }
        }
    }

    var displayedFilter: EntityFilter? {
        didSet {
            refresh()
        }
    }

    var filteredType: FilterableEntityType = .harvest {
        didSet {
            onFilteredTypeChanged(type: filteredType)
        }
    }



    private lazy var topContainer: UIStackView = {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill

        container.addView(showingEntriesForOthersLabel)
        container.addView(buttonsContainer)
        container.addView(clearSelectionsArea)
        return container
    }()

    private lazy var showingEntriesForOthersLabel: UILabel = {
        let label = UILabel().configure(
            for: .label,
            textAlignment: .center,
            numberOfLines: 0
        )
        label.backgroundColor = UIColor.applicationColor(GreyLight)
        label.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(30).priority(999)
        }
        label.isHidden = true

        label.text = "FilterShowingEntriesForOthers".localized()

        return label
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

        button.isHidden = (filteredType != .pointOfInterest)
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
    }

    func onEntityFilterChanged(change: EntityFilterChange) {
        enableSrva = RiistaSettings.userInfo()?.enableSrva.boolValue ?? false

        let newFilter = change.filter

        guard let currentFilter = displayedFilter else {
            // no need to check anything if there's no valid filter
            displayedFilter = newFilter
            return
        }

        // only update filterview data (and override e.g. point-of-interest selection) if
        // changes have been made elsewhere
        if (currentFilter.updateTimeStamp < newFilter.updateTimeStamp && isFilterSupported(filter: newFilter)) {
            displayedFilter = newFilter
        }
    }

    func refresh() {
        guard let displayedFilter = displayedFilter else {
            return
        }

        filteredType = displayedFilter.entityType

        if let filter = displayedFilter as? HarvestFilter {
            updateSeasonOrYearFiltering(year: filter.seasonStartYear, isSrva: false)
            updateSpeciesFiltering(speciesCategory: filter.speciesCategory, species: filter.species)
        } else if let filter = displayedFilter as? ObservationFilter {
            updateSeasonOrYearFiltering(year: filter.seasonStartYear, isSrva: false)
            updateSpeciesFiltering(speciesCategory: filter.speciesCategory, species: filter.species)
        } else if let filter = displayedFilter as? SrvaFilter {
            updateSeasonOrYearFiltering(year: filter.calendarYear, isSrva: true)
            updateSpeciesFiltering(speciesCategory: nil, species: filter.species)
        } else if displayedFilter is PointOfInterestFilter {
            updateSpeciesFiltering(speciesCategory: nil, species: [])
        }

        updateShowingEntriesForOthersLabel(showingEntriesForOtherActors: displayedFilter.showEntriesForOtherActors)
    }

    func updateTexts() {
        showingEntriesForOthersLabel.text = "FilterShowingEntriesForOthers".localized()
        clearSelectionsLabel.text = "FilterClearSpeciesFilter".localized()
        typeButton.setTitle(filteredType.localizationKey.localized(), for: .normal)
        listPoisButton.setTitle("PointsOfInterestListButtonTitle".localized(), for: .normal)
    }

    private func updateShowingEntriesForOthersLabel(showingEntriesForOtherActors: Bool?) {
        let hideLabel: Bool
        if let showingEntriesForOtherActors = showingEntriesForOtherActors {
            let canShowForOthers = HarvestSettingsControllerKt.showActorSelection(RiistaSDK.shared.preferences)
            hideLabel = !canShowForOthers || !showingEntriesForOtherActors
        } else {
            hideLabel = true
        }

        if (showingEntriesForOthersLabel.isHidden != hideLabel) {
            UIView.animate(withDuration: AppConstants.Animations.durationShort) { [weak self] in
                self?.showingEntriesForOthersLabel.isHidden = hideLabel
            }
        }
    }

    private func isFilterSupported(filter: EntityFilter) -> Bool {
        enabledFilteredTypes.contains(filter.entityType)
    }

    private func updateSeasonOrYearFiltering(year: Int?, isSrva: Bool) {
        let seasonButtonText = year?.formatToSeasonsText(srva: isSrva) ?? "-"
        seasonsButton.setTitle(seasonButtonText, for: .normal)
    }

    private func updateSpeciesFiltering(
        speciesCategory: Int?,
        species: [RiistaCommon.Species]
    ) {
        if (speciesCategory == nil && species.isEmpty) {
            clearSelectionsArea.isHidden = true
        }

        // indicate category if one exists
        if let speciesCategory = speciesCategory {
            setSelectedCategory(categoryCode: speciesCategory)
            return
        }

        setSelectedSpecies(species: species)
    }

    func setSelectedSpecies(species: [RiistaCommon.Species]) {
        let speciesButtonText: String
        switch species.count {
        case 0:
            speciesButtonText = "ChooseSpecies".localized()
        case 1:
            if species[0] is Species.Other {
                speciesButtonText = "SrvaOtherSpeciesDescription".localized()
            } else if let speciesCode = species[0].knownSpeciesCodeOrNull()?.intValue,
                      let speciesName = RiistaGameDatabase.sharedInstance()?.species(byId: speciesCode)?.name {
                speciesButtonText = RiistaUtils.name(withPreferredLanguage: speciesName)
            }
            else {
                speciesButtonText = "\(species.count) " + "FilterSelectedSpeciesCount".localized()
            }

            showSpeciesClear()
        default:
            speciesButtonText = "\(species.count) " + "FilterSelectedSpeciesCount".localized()

            showSpeciesClear()
        }

        speciesButton.setTitle(speciesButtonText, for: .normal)
    }

    func setSelectedCategory(categoryCode: Int) {
        let category = RiistaGameDatabase.sharedInstance()?.categories[categoryCode] as! RiistaSpeciesCategory
        speciesButton.setTitle(RiistaUtils.name(withPreferredLanguage: category.name), for: .normal)

        showSpeciesClear()
    }

    func showSpeciesClear() {
        self.clearSelectionsArea.isHidden = false
    }

    func clearSpeciesFilter() {
        guard let filter = displayedFilter else { return }

        UIView.animate(withDuration: AppConstants.Animations.durationShort) {
            self.clearSelectionsArea.isHidden = true
        }

        changeListener?.onFilterChangeRequested(
            filter: filter.changeSpecies(speciesCategoryId: nil, species: [])
        )
    }

    private func onTypeClicked() {
        let dropDown = DropDown()

        let filteredTypes = enabledFilteredTypes

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

    private func onFilteredTypeSelected(_ type: FilterableEntityType) {
        guard let filter = displayedFilter else { return }

        changeListener?.onFilterChangeRequested(
            filter: filter.changeEntityType(entityType: type)
        )
    }

    private func onSeasonsButtonClicked() {
        if (filteredType == .pointOfInterest) {
            Self.logger.w { "How can seasons button be clicked while POI is selected?" }
            return
        }

        let activeDataSource = dataSource?.activeDataSource

        activeDataSource?.getPossibleSeasonsOrYears { [weak self] seasonsOrYears in
            guard let self = self else { return }

            guard var seasonsOrYears = seasonsOrYears else {
                Self.logger.d { "No seasons available for type \(self.filteredType)" }
                return
            }

            if let currentSeasonOrYear = activeDataSource?.getCurrentSeasonOrYear() {
                if (!seasonsOrYears.contains(currentSeasonOrYear)) {
                    seasonsOrYears.insert(currentSeasonOrYear, at: 0)
                }
            } else {
                Self.logger.d { "No current season/year when seasons exist?" }
            }

            self.displaySeasonsFilterDropdown(seasonsOrYears: seasonsOrYears)
        }
    }

    private func displaySeasonsFilterDropdown(seasonsOrYears: [Int]) {
        let sortedYears = seasonsOrYears.sorted(by: >)

        let dropDown = DropDown()
        dropDown.anchorView = seasonsButton
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y: seasonsButton.plainView.bounds.height)
        dropDown.dataSource = sortedYears.map { year in
            year.formatToSeasonsText(srva: filteredType == .srva)
        }

        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
            self?.onSeasonStartYearSelected(year: sortedYears[index])
        }

        dropDown.show()
    }

    private func onSeasonStartYearSelected(year: Int) {
        guard let filter = displayedFilter else { return }

        changeListener?.onFilterChangeRequested(
            filter: filter.changeYear(year: year)
        )
    }

    private func onSpeciesButtonClicked() {
        delegate?.presentSpeciesSelect()
    }

    private func onClearSelectionsClicked() {
        clearSpeciesFilter()
    }

    func onFilterSpeciesSelected(species: [Species]) {
        guard let filter = displayedFilter else { return }

        changeListener?.onFilterChangeRequested(
            filter: filter.changeSpecies(speciesCategoryId: nil, species: species)
        )
    }

    func onFilterCategorySelected(speciesCategoryId: Int) {
        guard let filter = displayedFilter else { return }

        let categorySpecies = RiistaGameDatabase.sharedInstance()?
            .speciesList(withCategoryId: speciesCategoryId) as? [RiistaSpecies]
            ?? []

        let species = categorySpecies.compactMap { species in
            Species.Known(speciesCode: Int32(species.speciesId))
        }

        let selectedCategoryId: Int?
        if (species.isEmpty) {
            selectedCategoryId = nil
        } else {
            selectedCategoryId = speciesCategoryId
        }

        changeListener?.onFilterChangeRequested(
            filter: filter.changeSpecies(speciesCategoryId: selectedCategoryId, species: species)
        )
    }

    func presentSpeciesSelect(navigationController: UINavigationController) {
        guard let storyBoard = navigationController.storyboard else {
            Self.logger.w { "No storyboard, cannot present species select!" }
            return
        }

        if (filteredType == .srva) {
            let destination = storyBoard.instantiateViewController(withIdentifier: "FilterSpeciesController") as! FilterSpeciesViewController
            destination.delegate = self
            destination.isSrva = true

            navigationController.pushViewController(destination, animated: true)
        }
        else {
            let destination = storyBoard.instantiateViewController(withIdentifier: "FilterCategoryController") as! FilterCategoryViewController
            destination.delegate = self

            navigationController.pushViewController(destination, animated: true)
        }
    }

    private func onListPoisClicked() {
        delegate?.onFilterPointOfInterestListClicked()
    }

    private func onFilteredTypeChanged(type: FilterableEntityType) {
        typeButton.setTitle(type.localizationKey.localized(), for: .normal)

        let viewHiddenStatuses: [UIView : Bool]
        switch type {
        case .harvest, .observation, .srva:
            viewHiddenStatuses = [
                seasonsButton : false,
                speciesButton : false,
                listPoisButton : true
            ]
        case .pointOfInterest:
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

    private func createDropdownButton() -> CustomizableMaterialButton {
        let button = CustomizableMaterialButton(config: DROPDOWN_BUTTON_CONFIG)
        button.bottomIcon = UIImage(named: "arrow_drop_down")
        button.updateLayoutMargins(horizontal: 4, vertical: 2)
        return button
    }
}

fileprivate extension FilterableEntityType {
    var localizationKey: String {
        switch self {
        case .harvest:          return "Harvest"
        case .observation:      return "Observation"
        case .srva:             return "Srva"
        case .pointOfInterest:  return "PointsOfInterest"
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
