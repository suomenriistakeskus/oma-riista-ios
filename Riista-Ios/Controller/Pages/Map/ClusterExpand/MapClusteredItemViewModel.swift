import Foundation
import DifferenceKit
import RiistaCommon

typealias BackendId = Int64
typealias SpeciesCode = Int32

class MapClusteredItemViewModel: Differentiable {
    enum ItemType {
        case harvest
        case observation

        var name: String {
            String(describing: self)
        }
    }

    let id: BackendId
    let itemType: ItemType

    var differenceIdentifier: BackendId { id }

    init(id: BackendId, itemType: ItemType) {
        self.id = id
        self.itemType = itemType
    }

    func isContentEqual(to source: MapClusteredItemViewModel) -> Bool {
        return id == source.id && itemType == source.itemType
    }
}


class MapHarvestViewModel: MapClusteredItemViewModel {
    let speciesCode: SpeciesCode
    let acceptStatus: AcceptStatus
    let pointOfTime: LocalDateTime
    let description: String?

    init(
        id: BackendId,
        speciesCode: SpeciesCode,
        acceptStatus: AcceptStatus,
        pointOfTime: LocalDateTime,
        description: String?
    ) {
        self.speciesCode = speciesCode
        self.acceptStatus = acceptStatus
        self.pointOfTime = pointOfTime
        self.description = description

        super.init(id: id, itemType: .harvest)
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
        id: BackendId,
        speciesCode: SpeciesCode,
        acceptStatus: AcceptStatus,
        pointOfTime: LocalDateTime,
        description: String?
    ) {
        self.speciesCode = speciesCode
        self.acceptStatus = acceptStatus
        self.pointOfTime = pointOfTime
        self.description = description

        super.init(id: id, itemType: .observation)
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
