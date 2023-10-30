import Foundation
import RiistaCommon

class HarvestDataSource: TypedFilterableEntityDataSource<CommonHarvest> {
    let onlyEntitiesWithImages: Bool

    private(set) lazy var controllerHolder: ControllerHolderWithCallbacks<ListCommonHarvestsViewModel, ListCommonHarvestsController> = {
        let controller = ListCommonHarvestsController(
            harvestContext: RiistaSDK.shared.harvestContext,
            listOnlyHarvestsWithImages: onlyEntitiesWithImages
        )

        let controllerHolder = ControllerHolderWithCallbacks(controller: controller)
        controllerHolder.onViewModelLoadedCallback = { [weak self] _ in
            self?.notifyViewModelLoaded()
        }

        controllerHolder.bindToViewModelLoadStatus()

        return controllerHolder
    }()

    var controller: ListCommonHarvestsController {
        controllerHolder.controller
    }

    private var viewModel: ListCommonHarvestsViewModel? {
        controller.getLoadedViewModelOrNull()
    }

    private var fetchedHarvests: [CommonHarvest] {
        viewModel?.filteredHarvests ?? []
    }


    private var seasonStartFilter: Int = Int(Date().toLocalDate().getHuntingYear())
    private var speciesFilter: [RiistaCommon.Species] = []

    init(onlyEntitiesWithImages: Bool) {
        self.onlyEntitiesWithImages = onlyEntitiesWithImages
        super.init(filteredEntityType: .harvest)
    }

    override func fetchEntities() {
        controllerHolder.loadViewModel(refresh: false)
    }

    private func notifyViewModelLoaded() {
        listener?.onDataSourceDataUpdated(for: filteredEntityType)
    }

    override func getSeasonStats() -> SeasonStats? {
        let seasonStats = SeasonStats.empty()
        fetchedHarvests.forEach { harvest in
            guard let speciesCode = harvest.species.knownSpeciesCodeOrNull()?.intValue else {
                return
            }

            if let species = RiistaGameDatabase.sharedInstance().species(byId: speciesCode) {
                seasonStats.increaseCategoryAmount(
                    categoryId: species.categoryId,
                    by: Int(harvest.amount)
                )
            }
        }

        return seasonStats
    }

    override func getPossibleSeasonsOrYears(_ onCompleted: @escaping ([Int]?) -> Void) {
        let seasons = viewModel?.harvestHuntingYears
            .compactMap { harvestHuntingYear in
                harvestHuntingYear.intValue
            } ?? []

        onCompleted(seasons)
    }

    override func getCurrentSeasonOrYear() -> Int? {
        return Int(Date().toLocalDate().getHuntingYear())
    }

    override func onApplyFilter(
        newFilter: EntityFilter,
        oldFilter: EntityFilter?,
        onFilterApplied: @escaping OnFilterApplied
    ) {
        guard let newFilter = newFilter as? HarvestFilter else {
            fatalError("Only supporting HarvestFilter for HarvestDataSource")
        }

        // filters will be applied as pending filter if viewmodel has not been yet loaded
        let canShowForOthers = HarvestSettingsControllerKt.showActorSelection(RiistaSDK.shared.preferences)
        let ownHarvests = !canShowForOthers || !newFilter.showEntriesForOtherActors
        controller.setFilters(
            ownHarvests: ownHarvests,
            huntingYear: newFilter.seasonStartYear.toKotlinInt(),
            species: newFilter.species,
            completionHandler: handleOnMainThread { [weak self] _ in
                guard let _ = self else { return }

                onFilterApplied(true)
            }
        )
    }

    override func getSectionName(sectionIndex: Int) -> String? {
        guard let viewModel = viewModel else {
            return nil
        }

        guard let yearMonth = viewModel.filteredHarvestsByHuntingYearMonth.getOrNil(index: sectionIndex)?.yearMonth else {
            return nil
        }

        let firstDateOfMonth = LocalDate(year: yearMonth.year, monthNumber: yearMonth.monthNumber, dayOfMonth: 1)
        return MonthNameFormatter.formatMonthName(date: firstDateOfMonth.toFoundationDate())
    }

    override func getTotalEntityCount() -> Int {
        fetchedHarvests.count
    }

    override func getSectionCount() -> Int {
        getYearMonthCount()
    }

    override func getSectionEntityCount(sectionIndex: Int) -> Int? {
        guard let yearMonthData = getYearMonthData(yearMonthIndex: sectionIndex) else {
            return nil
        }

        return yearMonthData.entities.count
    }

    override func getEntities() -> [CommonHarvest] {
        fetchedHarvests
    }

    override open func getEntity(index: Int) -> CommonHarvest? {
        fetchedHarvests.getOrNil(index: index)
    }

    override open func getEntity(indexPath: IndexPath) -> CommonHarvest? {
        guard let yearMonthData = getYearMonthData(yearMonthIndex: indexPath.section) else {
            return nil
        }

        return yearMonthData.entities.getOrNil(index: indexPath.row) as? CommonHarvest
    }

    private func getYearMonthCount() -> Int {
        return viewModel?.filteredHarvestsByHuntingYearMonth.count ?? 0
    }

    private func getYearMonthData(yearMonthIndex: Int) -> EntitiesByYearMonth<CommonHarvest>? {
        guard let viewModel = viewModel else {
            return nil
        }

        return viewModel.filteredHarvestsByHuntingYearMonth.getOrNil(index: yearMonthIndex)
    }
}

