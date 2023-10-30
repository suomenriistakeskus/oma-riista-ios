import Foundation
import RiistaCommon

class PointOfInterestDataSource: TypedFilterableEntityDataSource<PointOfInterest> {

    private(set) lazy var controllerHolder: ControllerHolderWithCallbacks<PoisViewModel, PoiController> = {
        let controller = PoiController(
            poiContext: RiistaSDK.shared.poiContext,
            externalId: RiistaSettings.activeClubAreaMapId(),
            initialFilter: PoiFilter(poiFilterType: PoiFilter.PoiFilterType.all)
        )

        let controllerHolder = ControllerHolderWithCallbacks(controller: controller)
        controllerHolder.onViewModelLoadedCallback = { [weak self] _ in
            self?.refreshFetchedEntities()
        }

        controllerHolder.bindToViewModelLoadStatus()

        return controllerHolder
    }()

    var poiController: PoiController {
        controllerHolder.controller
    }

    private var fetchedPointsOfInterest: [PointOfInterest] = []

    private var viewModel: PoisViewModel? {
        poiController.getLoadedViewModelOrNull()
    }

    init() {
        super.init(filteredEntityType: .pointOfInterest)
    }

    override func onApplyFilter(
        newFilter: EntityFilter,
        oldFilter: EntityFilter?,
        onFilterApplied: @escaping OnFilterApplied
    ) {
        guard let _ = newFilter as? PointOfInterestFilter else {
            fatalError("Only supporting PointOfInterestFilter for PointOfInterestDataSource")
        }

        onFilterApplied(false)
    }

    override func fetchEntities() {
        controllerHolder.loadViewModel(refresh: false)
    }

    private func refreshFetchedEntities() {
        guard let viewModel = viewModel else {
            return
        }

        fetchedPointsOfInterest = viewModel.pois?.filteredPois.flatMap { poiLocationGroup in
            poiLocationGroup.locations.map { poiLocation in
                PointOfInterest(
                    group: poiLocationGroup,
                    poiLocation: poiLocation
                )
            }
        } ?? []

        listener?.onDataSourceDataUpdated(for: filteredEntityType)
    }

    override func getPossibleSeasonsOrYears(_ onCompleted: @escaping ([Int]?) -> Void) {
        // no seasons / years
        onCompleted(nil)
    }

    override func getCurrentSeasonOrYear() -> Int? {
        // no seasons / years
        return nil
    }

    override func getSeasonStats() -> SeasonStats? {
        return nil
    }

    override func getTotalEntityCount() -> Int {
        fetchedPointsOfInterest.count
    }

    override func getSectionCount() -> Int {
        return 1
    }

    override func getSectionName(sectionIndex: Int) -> String? {
        return nil
    }

    override func getSectionEntityCount(sectionIndex: Int) -> Int? {
        getTotalEntityCount()
    }

    override func getEntities() -> [PointOfInterest] {
        fetchedPointsOfInterest
    }

    override open func getEntity(index: Int) -> PointOfInterest? {
        fetchedPointsOfInterest.getOrNil(index: index)
    }

    override open func getEntity(indexPath: IndexPath) -> PointOfInterest? {
        getEntity(index: indexPath.row)
    }
}

