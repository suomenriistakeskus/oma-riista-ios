import Foundation


class MapDataSource: UnifiedEntityDataSource {

    private weak var markerManager: MapMarkerManager?

    var showMarkers: Bool {
        didSet {
            updateMarkers()
        }
    }

    weak var dataSourceListener: EntityDataSourceListener?

    init(markerManager: MapMarkerManager) {
        self.markerManager = markerManager
        self.showMarkers = true
        super.init(
            onlyEntitiesWithImages: false,
            supportedDataSourceTypes: [.harvest, .observation, .srva, .pointOfInterest]
        )
    }

    override func reloadContent(_ onCompleted: OnCompleted? = nil) {
        fetchEntitiesAndReloadMarkers(onCompleted)
    }

    override func onFilterApplied(dataSourceChanged: Bool, filteredDataChanged: Bool) {
        if (!dataSourceChanged && !filteredDataChanged && !shouldReloadData) {
            print("No need to reload map data!")
            return
        }

        fetchEntitiesAndReloadMarkers()
    }

    private func fetchEntitiesAndReloadMarkers(_ onCompleted: OnCompleted? = nil) {
        guard let dataSource = activeDataSource else {
            print("No data source, cannot fetch entities!")
            return
        }

        shouldReloadData = false

        dataSource.fetchEntities()
    }


    // MARK: EntityDataSourceListener

    override func onDataSourceDataUpdated(for entityType: FilterableEntityType) {
        guard let currentEntityType = activeDataSource?.filteredEntityType, currentEntityType == entityType else {
            return
        }

        self.updateMarkers()
        self.dataSourceListener?.onDataSourceDataUpdated(for: entityType)
    }

    private func updateMarkers() {
        guard let markerManager = markerManager else {
            return
        }

        markerManager.removeAllMarkers()

        if (!showMarkers) {
            return
        }

        guard let filteredType = activeDataSource?.filteredEntityType else {
            return
        }

        switch filteredType {
        case .harvest:
            markerManager.markerStorage.harvests = getHarvests()
        case .observation:
            markerManager.markerStorage.observations = getObservations()
        case .srva:
            markerManager.markerStorage.srvas = getSrvas()
        case .pointOfInterest:
            markerManager.markerStorage.pointsOfInterest = getPointsOfInterest()
        }

        markerManager.showMarkersOfType(markerTypes: [filteredType.mapMarkerType])
    }
}


fileprivate extension FilterableEntityType {
    var mapMarkerType: MapMarkerType {
        switch self {
        case .harvest:              return .harvest
        case .observation:          return .observation
        case .srva:                 return .srva
        case .pointOfInterest:      return .pointOfInterest
        }
    }
}
