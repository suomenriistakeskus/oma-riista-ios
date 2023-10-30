import Foundation


/*
 More information about filter implementation in SharedEntityFilterState.
 */

typealias OnFilterApplied = (_ filteredContentsChanged: Bool) -> Void

// base class for all data filterable data sources. Explicitly doesn't contain entity type
// information as that eases assigning data sources to common properties
class FilterableEntityDataSource {
    let filteredEntityType: FilterableEntityType
    private(set) var filter: EntityFilter?

    weak var listener: EntityDataSourceListener?

    init(filteredEntityType: FilterableEntityType) {
        self.filteredEntityType = filteredEntityType
    }

    func applyFilter(newFilter: EntityFilter, _ onFilterApplied: @escaping OnFilterApplied) {
        if (newFilter.entityType != filteredEntityType) {
            onFilterApplied(false)
            return
        }

        let oldFilter = filter
        filter = newFilter

        onApplyFilter(newFilter: newFilter, oldFilter: oldFilter, onFilterApplied: onFilterApplied)
    }

    func onApplyFilter(
        newFilter: EntityFilter,
        oldFilter: EntityFilter?,
        onFilterApplied: @escaping OnFilterApplied
    ) {
        fatalError("Subclasses are required to implement onApplyFilter(newFilter:oldFilter:onFilterApplied:)")
    }

    /**
     * Datasource should fetch entities and report progress using listener callbacks.
     */
    func fetchEntities() {
        fatalError("Subclasses are required to implement fetchEntities()")
    }

    func getPossibleSeasonsOrYears(_ onCompleted: @escaping ([Int]?) -> Void) {
        fatalError("Subclasses are required to implement getPossibleSeasonsOrYears()")
    }

    func getCurrentSeasonOrYear() -> Int? {
        fatalError("Subclasses are required to implement getCurrentSeasonOrYear()")
    }

    func getSeasonStats() -> SeasonStats? {
        fatalError("Subclasses are required to implement getSeasonStats()")
    }

    func getTotalEntityCount() -> Int {
        fatalError("Subclasses are required to implement getTotalEntityCount()")
    }

    func getSectionCount() -> Int {
        fatalError("Subclasses are required to implement getSectionCount()")
    }

    func getSectionName(sectionIndex: Int) -> String? {
        fatalError("Subclasses are required to implement getSectionName(sectionIndex:)")
    }

    func getSectionEntityCount(sectionIndex: Int) -> Int? {
        fatalError("Subclasses are required to implement getSectionEntityCount(sectionIndex:)")
    }
}


class TypedFilterableEntityDataSource<EntityType>: FilterableEntityDataSource {

    func getEntities() -> [EntityType] {
        fatalError("Subclasses are required to implement getEntities()")
    }

    func getEntity(index: Int) -> EntityType? {
        fatalError("Subclasses are required to implement getEntity(index:)")
    }

    /**
     * Get an entity from a section.
     */
    func getEntity(indexPath: IndexPath) -> EntityType? {
        fatalError("Subclasses are required to implement getEntity(indexPath:)")
    }
}
