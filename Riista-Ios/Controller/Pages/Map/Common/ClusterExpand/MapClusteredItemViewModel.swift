import Foundation
import DifferenceKit
import RiistaCommon

typealias BackendId = Int64
typealias SpeciesCode = Int32

enum ItemId: Hashable {
    case remote(id: BackendId)
    case commonLocal(commonLocalId: KotlinLong)
    case pointOfInterest(poiGroupId: Int64, poiLocationId: Int64)

    var remoteId: BackendId? {
        if case .remote(let remoteId) = self {
            return remoteId
        }

        return nil
    }

    var commonLocalId: KotlinLong? {
        if case .commonLocal(let commonLocalId) = self {
            return commonLocalId
        }

        return nil
    }
}


class MapClusteredItemViewModel: Differentiable {
    enum ItemType {
        case harvest, observation, srva, pointOfInterest

        var name: String {
            String(describing: self)
        }
    }

    let id: ItemId
    let itemType: ItemType
    let sortCriteria: String

    var differenceIdentifier: ItemId { id }

    init(id: ItemId, itemType: ItemType, sortCriteria: String) {
        self.id = id
        self.itemType = itemType
        self.sortCriteria = sortCriteria
    }

    func isContentEqual(to source: MapClusteredItemViewModel) -> Bool {
        return id == source.id &&
            itemType == source.itemType &&
            sortCriteria == source.sortCriteria
    }
}


class MapHarvestViewModel: MapClusteredItemViewModel {
    let speciesCode: SpeciesCode
    let acceptStatus: AcceptStatus
    let pointOfTime: LocalDateTime
    let description: String?

    init(
        id: ItemId,
        speciesCode: SpeciesCode,
        acceptStatus: AcceptStatus,
        pointOfTime: LocalDateTime,
        description: String?
    ) {
        self.speciesCode = speciesCode
        self.acceptStatus = acceptStatus
        self.pointOfTime = pointOfTime
        self.description = description

        super.init(id: id, itemType: .harvest, sortCriteria: pointOfTime.toStringISO8601())
    }

    override func isContentEqual(to source: MapClusteredItemViewModel) -> Bool {
        guard let other = source as? MapHarvestViewModel else {
            return false
        }

        return super.isContentEqual(to: source) &&
            speciesCode == other.speciesCode &&
            acceptStatus == other.acceptStatus &&
            pointOfTime == other.pointOfTime &&
            description == other.description
    }
}

class MapObservationViewModel: MapClusteredItemViewModel {
    let speciesCode: SpeciesCode
    let acceptStatus: AcceptStatus
    let pointOfTime: LocalDateTime
    let description: String?

    init(
        id: ItemId,
        speciesCode: SpeciesCode,
        acceptStatus: AcceptStatus,
        pointOfTime: LocalDateTime,
        description: String?
    ) {
        self.speciesCode = speciesCode
        self.acceptStatus = acceptStatus
        self.pointOfTime = pointOfTime
        self.description = description

        super.init(id: id, itemType: .observation, sortCriteria: pointOfTime.toStringISO8601())
    }

    override func isContentEqual(to source: MapClusteredItemViewModel) -> Bool {
        guard let other = source as? MapObservationViewModel else {
            return false
        }

        return super.isContentEqual(to: source) &&
            speciesCode == other.speciesCode &&
            acceptStatus == other.acceptStatus &&
            pointOfTime == other.pointOfTime &&
            description == other.description
    }
}


class MapSrvaViewModel: MapClusteredItemViewModel {
    let species: Species
    let otherSpeciesDescription: String?
    let acceptStatus: AcceptStatus
    let pointOfTime: LocalDateTime
    let description: String?

    init(
        id: ItemId,
        species: Species,
        otherSpeciesDescription: String?,
        acceptStatus: AcceptStatus,
        pointOfTime: LocalDateTime,
        description: String?
    ) {
        self.species = species
        self.otherSpeciesDescription = otherSpeciesDescription
        self.acceptStatus = acceptStatus
        self.pointOfTime = pointOfTime
        self.description = description

        super.init(id: id, itemType: .srva, sortCriteria: pointOfTime.toStringISO8601())
    }

    override func isContentEqual(to source: MapClusteredItemViewModel) -> Bool {
        guard let other = source as? MapSrvaViewModel else {
            return false
        }

        return super.isContentEqual(to: source) &&
            species == other.species &&
            otherSpeciesDescription == other.otherSpeciesDescription &&
            acceptStatus == other.acceptStatus &&
            pointOfTime == other.pointOfTime &&
            description == other.description
    }
}

class MapPointOfInterestViewModel: MapClusteredItemViewModel {
    let pointOfInterest: PointOfInterest

    init(pointOfInterest: PointOfInterest) {
        self.pointOfInterest = pointOfInterest

        super.init(
            id: .pointOfInterest(poiGroupId: pointOfInterest.group.id, poiLocationId: pointOfInterest.poiLocation.id),
            itemType: .pointOfInterest,
            sortCriteria: Self.createSortCriteria(pointOfInterest: pointOfInterest)
        )
    }

    override func isContentEqual(to source: MapClusteredItemViewModel) -> Bool {
        guard let other = source as? MapPointOfInterestViewModel else {
            return false
        }

        return super.isContentEqual(to: source) &&
            pointOfInterest.group.isEqual(other.pointOfInterest.group) &&
            pointOfInterest.poiLocation.isEqual(other.pointOfInterest.poiLocation)
    }

    private class func createSortCriteria(pointOfInterest: PointOfInterest) -> String {
        // sort based on visible ids (group - poi location). By default expanded cluster items
        // are sorted largest first so adjust values so that lowest ids are first here
        let groupSortCriteria = Int64.max - abs(Int64(pointOfInterest.group.visibleId))
        let locationSortCriteria = Int64.max - abs(Int64(pointOfInterest.poiLocation.visibleId))
        return "\(groupSortCriteria)-\(locationSortCriteria)"
    }
}
