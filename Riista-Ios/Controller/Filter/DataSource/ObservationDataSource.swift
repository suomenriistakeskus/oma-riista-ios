import Foundation
import RiistaCommon

class ObservationDataSource: TypedFilterableEntityDataSource<CommonObservation> {
    let onlyEntitiesWithImages: Bool

    private(set) lazy var controllerHolder: ControllerHolderWithCallbacks<ListCommonObservationsViewModel, ListCommonObservationsController> = {
        let controller = ListCommonObservationsController(
            metadataProvider: RiistaSDK.shared.metadataProvider,
            observationContext: RiistaSDK.shared.observationContext,
            listOnlyObservationsWithImages: onlyEntitiesWithImages
        )

        let controllerHolder = ControllerHolderWithCallbacks(controller: controller)
        controllerHolder.onViewModelLoadedCallback = { [weak self] _ in
            self?.notifyViewModelLoaded()
        }

        controllerHolder.bindToViewModelLoadStatus()

        return controllerHolder
    }()

    var controller: ListCommonObservationsController {
        controllerHolder.controller
    }

    private var viewModel: ListCommonObservationsViewModel? {
        controller.getLoadedViewModelOrNull()
    }

    private var fetchedObservations: [CommonObservation] {
        viewModel?.filteredObservations ?? []
    }


    private var seasonStartFilter: Int = Int(Date().toLocalDate().getHuntingYear())
    private var speciesFilter: [RiistaCommon.Species] = []

    init(onlyEntitiesWithImages: Bool) {
        self.onlyEntitiesWithImages = onlyEntitiesWithImages
        super.init(filteredEntityType: .observation)
    }

    override func fetchEntities() {
        controllerHolder.loadViewModel(refresh: false)
    }

    private func notifyViewModelLoaded() {
        listener?.onDataSourceDataUpdated(for: filteredEntityType)
    }

    override func getSeasonStats() -> SeasonStats? {
        let seasonStats = SeasonStats.empty()
        fetchedObservations.forEach { observation in
            guard let speciesCode = observation.species.knownSpeciesCodeOrNull()?.intValue else {
                return
            }

            if let species = RiistaGameDatabase.sharedInstance().species(byId: speciesCode) {
                let specimenAmount = observation.totalSpecimenAmount?.intValue ?? observation.mooselikeSpecimenAmount

                seasonStats.increaseCategoryAmount(
                    categoryId: species.categoryId,
                    by: specimenAmount
                )
            }
        }

        return seasonStats
    }

    override func getPossibleSeasonsOrYears(_ onCompleted: @escaping ([Int]?) -> Void) {
        let seasons = viewModel?.observationHuntingYears
            .compactMap { observationHuntingYear in
                observationHuntingYear.intValue
            } ?? []

        onCompleted(seasons)
    }

    override func onFilterChanged(newFilter: EntityFilter, oldFilter: EntityFilter?) -> Bool {
        guard let newFilter = newFilter as? ObservationFilter else {
            fatalError("Only supporting ObservationFilter for ObservationDataSource")
        }

        // filters will be applied as pending filter if viewmodel has not been yet loaded
        controller.setFilters(
            huntingYear: Int32(newFilter.seasonStartYear),
            species: newFilter.species
        )

        return true
    }

    override func getSectionName(sectionIndex: Int) -> String? {
        guard let viewModel = viewModel else {
            return nil
        }

        guard let yearMonth = viewModel.filteredObservationsByHuntingYearMonth.getOrNil(index: sectionIndex)?.yearMonth else {
            return nil
        }

        let firstDateOfMonth = LocalDate(year: yearMonth.year, monthNumber: yearMonth.monthNumber, dayOfMonth: 1)
        return MonthNameFormatter.formatMonthName(date: firstDateOfMonth.toFoundationDate())
    }

    override func getTotalEntityCount() -> Int {
        fetchedObservations.count
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

    override func getEntities() -> [CommonObservation] {
        fetchedObservations
    }

    override open func getEntity(index: Int) -> CommonObservation? {
        fetchedObservations.getOrNil(index: index)
    }

    override open func getEntity(indexPath: IndexPath) -> CommonObservation? {
        guard let yearMonthData = getYearMonthData(yearMonthIndex: indexPath.section) else {
            return nil
        }

        return yearMonthData.entities.getOrNil(index: indexPath.row) as? CommonObservation
    }

    private func getYearMonthCount() -> Int {
        return viewModel?.filteredObservationsByHuntingYearMonth.count ?? 0
    }

    private func getYearMonthData(yearMonthIndex: Int) -> EntitiesByYearMonth<CommonObservation>? {
        guard let viewModel = viewModel else {
            return nil
        }

        return viewModel.filteredObservationsByHuntingYearMonth.getOrNil(index: yearMonthIndex)
    }
}

