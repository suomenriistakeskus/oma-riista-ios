import Foundation
import RiistaCommon

/*
 More information about filter implementation in SharedEntityFilterState.


 All entity filters in one file in order to utilize "file private" fields
 */

/**
 * The base class for entity filters (harvest, observation, srva, pointOfInterest). Keeps track of FilterData which
 * allows restoring previous filter values after e.g. momentarily viewing point of interests.
 */
class EntityFilter: CustomStringConvertible {
    let entityType: FilterableEntityType
    fileprivate let filterData: FilterData
    private let supportsSpeciesFilter: Bool
    private let supportsShowEntriesForOtherActorsFilter: Bool

    let updateTimeStamp: Foundation.Date

    var hasSpeciesFilter: Bool {
        supportsSpeciesFilter && !filterData.species.isEmpty
    }

    open var showEntriesForOtherActors: Bool? {
        return nil // not supported, override to change behaviour
    }

    var description: String {
        "\(type(of: self))(\(filterData), timeStamp: \(updateTimeStamp))"
    }

    fileprivate init(
        entityType: FilterableEntityType,
        filterData: FilterData,
        supportsSpeciesFilter: Bool,
        supportsShowEntriesForOtherActorsFilter: Bool
    ) {
        self.entityType = entityType
        self.filterData = filterData
        self.updateTimeStamp = Date()
        self.supportsSpeciesFilter = supportsSpeciesFilter
        self.supportsShowEntriesForOtherActorsFilter = supportsShowEntriesForOtherActorsFilter
    }

    func changeEntityType(entityType: FilterableEntityType) -> EntityFilter {
        if (self.entityType == entityType) {
            return self
        }

        switch entityType {
        case .harvest:              return HarvestFilter(filterData: filterData)
        case .observation:          return ObservationFilter(filterData: filterData)
        case .srva:                 return SrvaFilter(filterData: filterData)
        case .pointOfInterest:      return PointOfInterestFilter(filterData: filterData)
        }
    }

    func changeShowEntriesForOtherActors(showEntriesForOtherActors: Bool) -> EntityFilter {
        fatalError("Subclasses should implement this")
    }

    open func changeYear(year: Int) -> EntityFilter {
        fatalError("Subclasses should implement this")
    }

    func changeSpecies(speciesCategoryId: Int?, species: [RiistaCommon.Species]) -> EntityFilter {
        fatalError("Subclasses should implement this")
    }

    func ensureSpeciesDisplayed(species: RiistaCommon.Species) -> EntityFilter {
        fatalError("Subclasses should implement this")
    }
}


class HarvestFilter: EntityFilter {
    var seasonStartYear: Int {
        filterData.year
    }

    var speciesCategory: Int? {
        filterData.speciesCategoryId
    }

    var species: [RiistaCommon.Species] {
        filterData.species
    }

    override var showEntriesForOtherActors: Bool {
        filterData.showEntriesForOtherActors
    }

    fileprivate init(filterData: FilterData) {
        super.init(
            entityType: .harvest,
            filterData: filterData.validateSpecies { $0 is Species.Known }.preventFutureHuntingYear(),
            supportsSpeciesFilter: true,
            supportsShowEntriesForOtherActorsFilter: true
        )
    }

    convenience init(
        seasonStartYear: Int,
        speciesCategory: Int?,
        species: [RiistaCommon.Species],
        showEntriesForOtherActors: Bool
    ) {
        self.init(filterData: FilterData(
            year: seasonStartYear,
            speciesCategory: speciesCategory,
            species: species,
            showEntriesForOtherActors: showEntriesForOtherActors
        ))
    }

    override func changeYear(year: Int) -> EntityFilter {
        HarvestFilter(filterData: filterData.changeYear(year: year))
    }

    override func changeSpecies(speciesCategoryId: Int?, species: [RiistaCommon.Species]) -> EntityFilter {
        HarvestFilter(filterData: filterData.changeSpecies(speciesCategoryId: speciesCategoryId, species: species))
    }

    override func ensureSpeciesDisplayed(species: RiistaCommon.Species) -> EntityFilter {
        HarvestFilter(filterData: filterData.ensureSpeciesDisplayed(species: species))
    }

    override func changeShowEntriesForOtherActors(showEntriesForOtherActors: Bool) -> EntityFilter {
        HarvestFilter(
            filterData: filterData.changeShowEntriesForOtherActors(showEntriesForOtherActors: showEntriesForOtherActors)
        )
    }
}



class ObservationFilter: EntityFilter {
    var seasonStartYear: Int {
        filterData.year
    }

    var speciesCategory: Int? {
        filterData.speciesCategoryId
    }

    var species: [RiistaCommon.Species] {
        filterData.species
    }


    fileprivate init(filterData: FilterData) {
        super.init(
            entityType: .observation,
            filterData: filterData.validateSpecies { $0 is Species.Known }.preventFutureHuntingYear(),
            supportsSpeciesFilter: true,
            supportsShowEntriesForOtherActorsFilter: false
        )
    }

    override func changeYear(year: Int) -> EntityFilter {
        ObservationFilter(filterData: filterData.changeYear(year: year))
    }

    override func changeSpecies(speciesCategoryId: Int?, species: [RiistaCommon.Species]) -> EntityFilter {
        ObservationFilter(filterData: filterData.changeSpecies(speciesCategoryId: speciesCategoryId, species: species))
    }

    override func ensureSpeciesDisplayed(species: RiistaCommon.Species) -> EntityFilter {
        ObservationFilter(filterData: filterData.ensureSpeciesDisplayed(species: species))
    }

    override func changeShowEntriesForOtherActors(showEntriesForOtherActors: Bool) -> EntityFilter {
        logger.w { "ObservationFilter doesn't support changing show entries for other actors" }
        return ObservationFilter(
            filterData: filterData.changeShowEntriesForOtherActors(showEntriesForOtherActors: showEntriesForOtherActors)
        )
    }
}


class SrvaFilter: EntityFilter {
    private static let srvaSpecies = RiistaSDK.shared.metadataProvider.srvaMetadata.species + [Species.Other()]
    var calendarYear: Int {
        filterData.year
    }

    var species: [RiistaCommon.Species] {
        filterData.species
    }

    fileprivate init(filterData: FilterData) {
        super.init(
            entityType: .srva,
            filterData: filterData.validateSpecies { SrvaFilter.srvaSpecies.contains($0) },
            supportsSpeciesFilter: true,
            supportsShowEntriesForOtherActorsFilter: false
        )
    }

    override func changeYear(year: Int) -> EntityFilter {
        SrvaFilter(filterData: filterData.changeYear(year: year))
    }

    override func changeSpecies(speciesCategoryId: Int?, species: [RiistaCommon.Species]) -> EntityFilter {
        SrvaFilter(filterData: filterData.changeSpecies(
            speciesCategoryId: speciesCategoryId,
            species: species
        ))
    }

    override func ensureSpeciesDisplayed(species: RiistaCommon.Species) -> EntityFilter {
        SrvaFilter(filterData: filterData.ensureSpeciesDisplayed(species: species))
    }

    override func changeShowEntriesForOtherActors(showEntriesForOtherActors: Bool) -> EntityFilter {
        logger.w { "SrvaFilter doesn't support changing show entries for other actors" }
        return SrvaFilter(
            filterData: filterData.changeShowEntriesForOtherActors(showEntriesForOtherActors: showEntriesForOtherActors)
        )
    }
}


class PointOfInterestFilter: EntityFilter {
    fileprivate init(filterData: FilterData) {
        super.init(
            entityType: .pointOfInterest,
            filterData: filterData,
            supportsSpeciesFilter: false,
            supportsShowEntriesForOtherActorsFilter: false
        )
    }

    override func changeYear(year: Int) -> EntityFilter {
        logger.w { "PointOfInterestFilter doesn't support changing year" }
        return PointOfInterestFilter(filterData: filterData.changeYear(year: year))
    }

    override func changeSpecies(speciesCategoryId: Int?, species: [RiistaCommon.Species]) -> EntityFilter {
        logger.w { "PointOfInterestFilter doesn't support changing species" }
        return PointOfInterestFilter(filterData: filterData.changeSpecies(
            speciesCategoryId: speciesCategoryId,
            species: species
        ))
    }

    override func ensureSpeciesDisplayed(species: RiistaCommon.Species) -> EntityFilter {
        logger.w { "PointOfInterestFilter doesn't support ensuring species exists" }
        return PointOfInterestFilter(filterData: filterData.ensureSpeciesDisplayed(species: species))
    }

    override func changeShowEntriesForOtherActors(showEntriesForOtherActors: Bool) -> EntityFilter {
        logger.w { "PointOfInterestFilter doesn't support changing show entries for other actors" }
        return PointOfInterestFilter(
            filterData: filterData.changeShowEntriesForOtherActors(showEntriesForOtherActors: showEntriesForOtherActors)
        )
    }
}



fileprivate class FilterData: CustomStringConvertible {
    let year: Int
    let speciesCategoryId: Int?
    let species: [RiistaCommon.Species]
    let showEntriesForOtherActors: Bool

    var description: String {
        "year: \(year), speciesCategory: \(speciesCategoryId ?? -1), " +
        "species: \(species), showForOthers: \(showEntriesForOtherActors)"
    }

    init(year: Int, speciesCategory: Int?, species: [RiistaCommon.Species], showEntriesForOtherActors: Bool) {
        self.year = year
        self.speciesCategoryId = speciesCategory
        self.species = species
        self.showEntriesForOtherActors = showEntriesForOtherActors
    }

    func changeYear(year: Int) -> FilterData {
        FilterData(
            year: year,
            speciesCategory: self.speciesCategoryId,
            species: self.species,
            showEntriesForOtherActors: self.showEntriesForOtherActors
        )
    }

    func changeSpecies(speciesCategoryId: Int?, species: [RiistaCommon.Species]) -> FilterData {
        FilterData(
            year: self.year,
            speciesCategory: speciesCategoryId,
            species: species,
            showEntriesForOtherActors: self.showEntriesForOtherActors
        )
    }

    func ensureSpeciesDisplayed(species: RiistaCommon.Species) -> FilterData {
        if (self.species.contains(species) || self.species.isEmpty) {
            // already in filter or not filtering at all
            return self
        }

        // todo: don't invalidate category if given species is among category species
        return FilterData(
            year: self.year,
            speciesCategory: nil, // invalidate as category may not contain the species
            species: self.species + [species],
            showEntriesForOtherActors: self.showEntriesForOtherActors
        )
    }

    func changeShowEntriesForOtherActors(showEntriesForOtherActors: Bool) -> FilterData {
        FilterData(
            year: self.year,
            speciesCategory: self.speciesCategoryId,
            species: self.species,
            showEntriesForOtherActors: showEntriesForOtherActors
        )
    }

    func validateSpecies(_ shouldIncludeSpecies: (RiistaCommon.Species) -> Bool) -> FilterData {
        let validatedSpecies = species.filter { species in
            shouldIncludeSpecies(species)
        }

        let updatedSpeciesCategoryId: Int?
        if (validatedSpecies.count == species.count) {
            updatedSpeciesCategoryId = self.speciesCategoryId
        } else {
            // had to drop some species, don't keep category as that would indicate
            // that all category species are still selected
            updatedSpeciesCategoryId = nil
        }

        return changeSpecies(
            speciesCategoryId: updatedSpeciesCategoryId,
            species: validatedSpecies
        )
    }

    func preventFutureHuntingYear() -> FilterData {
        let currentHuntingYear = DatetimeUtil.huntingYearContaining(date: Date())
        if (self.year > currentHuntingYear) {
            return changeYear(year: currentHuntingYear)
        } else {
            return self
        }
    }
}

fileprivate extension Array where Element == RiistaCommon.Species {
    func keepOnlyKnownSpecies() -> [RiistaCommon.Species] {
        self.filter { species in
            species is Species.Known
        }
    }
}

fileprivate let logger = AppLogger(context: "EntityFilters", printTimeStamps: false)
