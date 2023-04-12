import Foundation
import RiistaCommon

class SrvaEventDataSource: TypedFilterableEntityDataSource<CommonSrvaEvent> {

    private(set) lazy var controllerHolder: ControllerHolderWithCallbacks<ListCommonSrvaEventsViewModel, ListCommonSrvaEventsController> = {
        let controller = ListCommonSrvaEventsController(
            metadataProvider: RiistaSDK.shared.metadataProvider,
            srvaContext: RiistaSDK.shared.srvaContext,
            listOnlySrvaEventsWithImages: onlyEntitiesWithImages
        )

        let controllerHolder = ControllerHolderWithCallbacks(controller: controller)
        controllerHolder.onViewModelLoadedCallback = { [weak self] _ in
            self?.notifyViewModelLoaded()
        }

        controllerHolder.bindToViewModelLoadStatus()

        return controllerHolder
    }()

    var controller: ListCommonSrvaEventsController {
        controllerHolder.controller
    }

    private var viewModel: ListCommonSrvaEventsViewModel? {
        controller.getLoadedViewModelOrNull()
    }

    private var fetchedSrvaEvents: [CommonSrvaEvent] {
        viewModel?.filteredSrvaEvents ?? []
    }

    private let onlyEntitiesWithImages: Bool

    init(onlyEntitiesWithImages: Bool) {
        self.onlyEntitiesWithImages = onlyEntitiesWithImages
        super.init(filteredEntityType: .srva)
    }

    override func fetchEntities() {
        controllerHolder.loadViewModel(refresh: false)
    }

    private func notifyViewModelLoaded() {
        listener?.onDataSourceDataUpdated(for: filteredEntityType)
    }

    override func getSeasonStats() -> SeasonStats? {
        let seasonStats = SeasonStats.empty()
        fetchedSrvaEvents.forEach { srvaEvent in
            guard let speciesCode = srvaEvent.species.knownSpeciesCodeOrNull()?.intValue else {
                return
            }

            if let species = RiistaGameDatabase.sharedInstance().species(byId: speciesCode) {
                seasonStats.increaseCategoryAmount(
                    categoryId: species.categoryId,
                    by: srvaEvent.specimens.count
                )
            }
        }

        return seasonStats
    }

    override func getPossibleSeasonsOrYears(_ onCompleted: @escaping ([Int]?) -> Void) {
        let years = viewModel?.srvaEventYears
            .compactMap { srvaYear in
                srvaYear.intValue
            } ?? []

        onCompleted(years)
    }

    override func onFilterChanged(newFilter: EntityFilter, oldFilter: EntityFilter?) -> Bool {
        guard let newFilter = newFilter as? SrvaFilter else {
            fatalError("Only supporting SrvaFilter for SrvaEventDataSource")
        }

        // filters will be applied as pending filter if viewmodel has not been yet loaded
        controller.setFilters(
            year: Int32(newFilter.calendarYear),
            species: newFilter.species
        )

        return true
    }

    override func getSectionName(sectionIndex: Int) -> String? {
        guard let viewModel = viewModel else {
            return nil
        }

        guard let yearMonth = viewModel.filteredSrvaEventsByYearMonth.getOrNil(index: sectionIndex)?.yearMonth else {
            return nil
        }

        let firstDateOfMonth = LocalDate(year: yearMonth.year, monthNumber: yearMonth.monthNumber, dayOfMonth: 1)
        return MonthNameFormatter.formatMonthName(date: firstDateOfMonth.toFoundationDate())
    }

    override func getTotalEntityCount() -> Int {
        fetchedSrvaEvents.count
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

    override func getEntities() -> [CommonSrvaEvent] {
        fetchedSrvaEvents
    }

    override open func getEntity(index: Int) -> CommonSrvaEvent? {
        fetchedSrvaEvents.getOrNil(index: index)
    }

    override open func getEntity(indexPath: IndexPath) -> CommonSrvaEvent? {
        guard let yearMonthData = getYearMonthData(yearMonthIndex: indexPath.section) else {
            return nil
        }

        return yearMonthData.entities.getOrNil(index: indexPath.row) as? CommonSrvaEvent
    }

    private func getYearMonthCount() -> Int {
        return viewModel?.filteredSrvaEventsByYearMonth.count ?? 0
    }

    private func getYearMonthData(yearMonthIndex: Int) -> EntitiesByYearMonth<CommonSrvaEvent>? {
        guard let viewModel = viewModel else {
            return nil
        }

        return viewModel.filteredSrvaEventsByYearMonth.getOrNil(index: yearMonthIndex)
    }

}

