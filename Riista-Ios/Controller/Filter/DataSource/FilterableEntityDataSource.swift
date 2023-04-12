import Foundation


/*
 More information about filter implementation in SharedEntityFilterState.
 */


// base class for all data filterable data sources. Explicitly doesn't contain entity type
// information as that eases assigning data sources to common properties
class FilterableEntityDataSource {
    let filteredEntityType: FilterableEntityType
    private(set) var filter: EntityFilter?

    weak var listener: EntityDataSourceListener?

    init(filteredEntityType: FilterableEntityType) {
        self.filteredEntityType = filteredEntityType
    }

    // return true if filtered contents were changed, false otherwise
    func applyFilter(newFilter: EntityFilter) -> Bool {
        if (newFilter.entityType != filteredEntityType) {
            return false
        }

        let oldFilter = filter
        filter = newFilter

        let changed = onFilterChanged(newFilter: newFilter, oldFilter: oldFilter)

        return changed
    }

    // return true if filtered contents were changed, false otherwise
    func onFilterChanged(newFilter: EntityFilter, oldFilter: EntityFilter?) -> Bool {
        fatalError("Subclasses are required to implement onFilterChanged(newFilter:oldFilter:)")
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
