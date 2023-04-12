import Foundation


class EntityFilterChange {
    /**
     * The new/current filter after change has been applied.
     */
    let filter: EntityFilter

    var previousFilter: EntityFilter? {
        previousFilters.last
    }

    /**
     * Previous filters. Only latest filter for each FilterableEntityType is kept.
     *
     * The previous filter is the last in the list. The current filter is not in the list.
     */
    private let previousFilters: [EntityFilter]


    convenience init(newFilter: EntityFilter) {
        self.init(newFilter: newFilter, previousFilters: [])
    }

    private init(newFilter: EntityFilter, previousFilters: [EntityFilter]) {
        self.filter = newFilter
        self.previousFilters = previousFilters
    }


    // filter changes

    func hasEntityTypeChanged() -> Bool {
        filter.entityType != previousFilter?.entityType
    }


    func getLastValidSupportedFilter(supportedFilterTypes: [FilterableEntityType]) -> EntityFilter? {
        return previousFilters.last { filter in
            supportedFilterTypes.contains(filter.entityType)
        }
    }


    // Creating new change

    func update(newFilter: EntityFilter) -> EntityFilterChange {
        EntityFilterChange(
            newFilter: newFilter,
            previousFilters: previousFilters.addingPreviousFilter(filter: self.filter)
        )
    }
}


fileprivate extension Array where Element == EntityFilter {
    func addingPreviousFilter(filter: EntityFilter) -> Array {
        var newPreviousFilters: [EntityFilter] = self

        // only keep last valid for each type
        let filterEntityType = filter.entityType
        newPreviousFilters.removeAll { $0.entityType == filterEntityType }
        newPreviousFilters.append(filter)

        return newPreviousFilters
    }
}
