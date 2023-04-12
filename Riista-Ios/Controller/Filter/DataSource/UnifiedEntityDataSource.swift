import Foundation
import RiistaCommon

/*
 More information about filter implementation in SharedEntityFilterState.
 */


enum EntityAccessMethod {
    case indexPath(_ indexPath: IndexPath)
    case index(_ index: Int)
}

/**
 * A data source that combines multiple other data sources. Also acts as EntityFilterChangeNotifier since that allows notifying interested
 * parties about filter changes on which data source has reacted.
 *
 * See more information about filtering in SharedEntityFilterState
 */
class UnifiedEntityDataSource: EntityFilterChangeNotifier, EntityFilterChangeListener, EntityDataSourceListener {
    let onlyEntitiesWithImages: Bool
    let supportedDataSourceTypes: [FilterableEntityType]

    /**
     * Should the datasource reload data next time it has a possibility to do so?
     */
    var shouldReloadData: Bool = false

    // explicitly allow public read access to data sources
    // -> allows accessing data source parameters / data from outside world
    private(set) lazy var harvestDataSource: HarvestDataSource = configure(
        dataSource: HarvestDataSource(onlyEntitiesWithImages: onlyEntitiesWithImages)
    )

    private(set) lazy var observationDataSource: ObservationDataSource = configure(
        dataSource: ObservationDataSource(onlyEntitiesWithImages: onlyEntitiesWithImages)
    )

    private(set) lazy var srvaDataSource: SrvaEventDataSource = configure(
        dataSource: SrvaEventDataSource(onlyEntitiesWithImages: onlyEntitiesWithImages)
    )

    private(set) lazy var pointOfInterestDataSource: PointOfInterestDataSource = configure(
        dataSource: PointOfInterestDataSource()
    )


    private(set) var activeDataSource: FilterableEntityDataSource?

    init(onlyEntitiesWithImages: Bool, supportedDataSourceTypes: [FilterableEntityType]) {
        self.onlyEntitiesWithImages = onlyEntitiesWithImages
        self.supportedDataSourceTypes = supportedDataSourceTypes
    }


    // MARK: Required to be implemented in subclasses

    func reloadContent(_ onCompleted: OnCompleted? = nil) {
        print("Subclasses should probably implement reloadContent()")
    }

    open func onFilterApplied(dataSourceChanged: Bool, filteredDataChanged: Bool) {
        print("Subclasses should probably implement onFilterApplied()")
    }


    // MARK: Getting stats

    /**
     * Assumed to be called after data has been reloaded --> synchronous.
     */
    func getSeasonStats() -> SeasonStats? {
        activeDataSource?.getSeasonStats()
    }


    // MARK: Accessing entities

    func getHarvests() -> [DiaryEntry] {
        harvestDataSource.getEntities()
    }

    func getHarvest(specifiedBy: EntityAccessMethod) -> DiaryEntry? {
        if (activeDataSource?.filteredEntityType != .harvest) {
            return nil
        }

        switch specifiedBy {
        case .indexPath(let indexPath):     return harvestDataSource.getEntity(indexPath: indexPath)
        case .index(let index):             return harvestDataSource.getEntity(index: index)
        }
    }

    func getObservations() -> [CommonObservation] {
        observationDataSource.getEntities()
    }

    func getObservation(specifiedBy: EntityAccessMethod) -> CommonObservation? {
        if (activeDataSource?.filteredEntityType != .observation) {
            return nil
        }

        switch specifiedBy {
        case .indexPath(let indexPath):     return observationDataSource.getEntity(indexPath: indexPath)
        case .index(let index):             return observationDataSource.getEntity(index: index)
        }
    }

    func getSrvas() -> [CommonSrvaEvent] {
        srvaDataSource.getEntities()
    }

    func getSrva(specifiedBy: EntityAccessMethod) -> CommonSrvaEvent? {
        if (activeDataSource?.filteredEntityType != .srva) {
            return nil
        }

        switch specifiedBy {
        case .indexPath(let indexPath):     return srvaDataSource.getEntity(indexPath: indexPath)
        case .index(let index):             return srvaDataSource.getEntity(index: index)
        }
    }

    func getPointsOfInterest() -> [PointOfInterest] {
        pointOfInterestDataSource.getEntities()
    }

    func getPointOfInterest(specifiedBy: EntityAccessMethod) -> PointOfInterest? {
        if (activeDataSource?.filteredEntityType != .pointOfInterest) {
            return nil
        }

        switch specifiedBy {
        case .indexPath(let indexPath):     return pointOfInterestDataSource.getEntity(indexPath: indexPath)
        case .index(let index):             return pointOfInterestDataSource.getEntity(index: index)
        }
    }


    // MARK: EntityDataSourceListener

    func onDataSourceDataUpdated(for entityType: FilterableEntityType) {
        fatalError("Subclasses are expected to implement onDataSourceDataUpdated(for:)")
    }


    // MARK: Reacting to filter changes

    func onEntityFilterChanged(change: EntityFilterChange) {
        let newFilter = change.filter
        let entityType = newFilter.entityType


        if (!supportedDataSourceTypes.contains(entityType)) {
            print("New filter \(newFilter) is not supported. Falling back to last supported filter.")
            fallbackToLastValidSupportedFilter(change: change)
            return
        }

        print("Changing entity filter to \(newFilter)")

        let dataSourceChanged = updateActiveDataSource(itemType: entityType)

        guard let activeDataSource = activeDataSource else {
            fatalError("Expecting active data source to exist after activating data source for type \(entityType)")
        }

        let filteredDataChanged = activeDataSource.applyFilter(newFilter: newFilter)

        onFilterApplied(dataSourceChanged: dataSourceChanged, filteredDataChanged: filteredDataChanged)
        notifyEntityFilterChanged(change: change)
    }

    private func fallbackToLastValidSupportedFilter(change: EntityFilterChange) {
        if let fallbackFilter = change.getLastValidSupportedFilter(supportedFilterTypes: supportedDataSourceTypes) {
            let changeToFallback = change.update(newFilter: fallbackFilter)
            onEntityFilterChanged(change: changeToFallback)
        }
    }

    private func updateActiveDataSource(itemType: FilterableEntityType) -> Bool {
        let newDataSource = getDataSource(itemType: itemType)
        if (newDataSource !== activeDataSource) {
            activeDataSource = newDataSource
            return true
        }

        return false
    }

    private func getDataSource(itemType: FilterableEntityType) -> FilterableEntityDataSource {
        switch itemType {
        case .harvest:          return harvestDataSource
        case .observation:      return observationDataSource
        case .srva:             return srvaDataSource
        case .pointOfInterest:  return pointOfInterestDataSource
        }
    }

    private func configure<T : FilterableEntityDataSource>(dataSource: T) -> T {
        dataSource.listener = self
        return dataSource
    }
}
