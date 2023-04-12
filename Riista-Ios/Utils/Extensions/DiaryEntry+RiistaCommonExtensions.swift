import Foundation
import RiistaCommon
import CoreData

extension DiaryEntry {

    func toCommonHarvest(objectId: NSManagedObjectID) -> CommonHarvest? {
        guard let dateTime = pointOfTime?.toLocalDateTime(),
              let location = coordinates?.toWGS84Coordinate().toETRSCoordinate(source: coordinates?.source ?? "") else {
                print("returning nil")
                return nil
        }

        return CommonHarvest(
            localId: nil,
            localUrl: objectId.uriRepresentation().absoluteString,
            id: remoteId?.toKotlinLong(),
            rev: rev?.toKotlinInt(),
            species: gameSpeciesCode?.toSpecies() ?? Species.Unknown(),
            geoLocation: location,
            pointOfTime: dateTime,
            description: diarydescription,
            canEdit: canEdit?.boolValue ?? false,
            images: parseEntityImages(),
            specimens: parseCommonSpecimens(),
            amount: amount?.toKotlinInt(),
            harvestSpecVersion: harvestSpecVersion?.int32Value ?? RiistaCommon.Constants.shared.HARVEST_SPEC_VERSION,
            harvestReportRequired: harvestReportRequired?.boolValue ?? false,
            harvestReportState: RiistaCommon.HarvestReportState.Companion.shared.toBackendEnumCompat(value: harvestReportState),
            permitNumber: permitNumber,
            permitType: nil, // todo: permit type
            stateAcceptedToHarvestPermit: RiistaCommon.StateAcceptedToHarvestPermit.Companion.shared.toBackendEnumCompat(value: stateAcceptedToHarvestPermit),
            deerHuntingType: RiistaCommon.DeerHuntingType.Companion.shared.toBackendEnumCompat(value: deerHuntingType),
            deerHuntingOtherTypeDescription: deerHuntingTypeDescription,
            mobileClientRefId: mobileClientRefId?.toKotlinLong(),
            harvestReportDone: harvestReportDone?.boolValue ?? false,
            rejected: harvestReportState == DiaryEntryHarvestStateRejected,
            feedingPlace: feedingPlace?.boolValue.toKotlinBoolean(),
            taigaBeanGoose: taigaBeanGoose?.boolValue.toKotlinBoolean(),
            greySealHuntingMethod: RiistaCommon.GreySealHuntingMethod.Companion.shared.toBackendEnumCompat(value: huntingMethod)
        )
    }

    @discardableResult
    func updateWithCommonHarvest(harvest: CommonHarvest, context: NSManagedObjectContext) -> DiaryEntry  {
        self.type = DiaryEntryTypeHarvest
        self.remoteId = harvest.id
        self.rev = harvest.rev
        self.gameSpeciesCode = harvest.species.toGameSpeciesCode()
        self.coordinates = harvest.geoLocation.toGeoCoordinate(context: context, existingCoordinates: self.coordinates)
        self.pointOfTime = harvest.pointOfTime.toFoundationDate()
        self.year = harvest.pointOfTime.year.toNSNumber()
        self.month = harvest.pointOfTime.monthNumber.toNSNumber()
        self.diarydescription = harvest.description_ ?? ""
        self.canEdit = harvest.canEdit.toNSNumber()
        self.diaryImages = (harvest.images.toDiaryImages(context: context, existingImages: self.diaryImages) as! Set<AnyHashable>)
        self.specimens = harvest.specimens.toHarvestSpecimens(context: context)
        self.amount = harvest.amount ?? 1
        self.harvestSpecVersion = harvest.harvestSpecVersion.toNSNumber()
        self.harvestReportRequired = harvest.harvestReportRequired.toNSNumber()
        self.harvestReportState = harvest.harvestReportState.rawBackendEnumValue
        self.permitNumber = harvest.permitNumber
        self.stateAcceptedToHarvestPermit = harvest.stateAcceptedToHarvestPermit.rawBackendEnumValue
        self.deerHuntingType = harvest.deerHuntingType.rawBackendEnumValue
        self.deerHuntingTypeDescription = harvest.deerHuntingOtherTypeDescription
        self.mobileClientRefId = harvest.mobileClientRefId
        self.harvestReportDone = harvest.harvestReportDone.toNSNumber()
        self.feedingPlace = harvest.feedingPlace
        self.taigaBeanGoose = harvest.taigaBeanGoose
        self.huntingMethod = harvest.greySealHuntingMethod.rawBackendEnumValue

        // ignore following for now
//        self.pendingOperation = ...
//        self.remote = ...
//        self.sent = ...

        return self
    }

    private func parseCommonSpecimens() -> [CommonHarvestSpecimen] {
        guard let specimens = specimens else {
            return []
        }

        var commonSpecimens = specimens.compactMap { specimen in
            (specimen as? RiistaSpecimen)?.toCommonHarvestSpecimen()
        }

        return ensureSpecimenCount(specimens: &commonSpecimens, count: amount?.intValue ?? specimens.count)
    }

    private func ensureSpecimenCount(specimens: inout [CommonHarvestSpecimen], count: Int) -> [CommonHarvestSpecimen] {
        while (specimens.count < count) {
            let specimen = CommonHarvestSpecimen(
                id: nil,
                rev: nil,
                gender: RiistaCommon.Gender.Companion.shared.toBackendEnumCompat(value: nil),
                age: RiistaCommon.GameAge.Companion.shared.toBackendEnumCompat(value: nil),
                weight: nil,
                weightEstimated: nil,
                weightMeasured: nil,
                fitnessClass: RiistaCommon.GameFitnessClass.Companion.shared.toBackendEnumCompat(value: nil),
                antlersLost: nil,
                antlersType: RiistaCommon.GameAntlersType.Companion.shared.toBackendEnumCompat(value: nil),
                antlersWidth: nil,
                antlerPointsLeft: nil,
                antlerPointsRight: nil,
                antlersGirth: nil,
                antlersLength: nil,
                antlersInnerWidth: nil,
                antlerShaftWidth: nil,
                notEdible: nil,
                alone: nil,
                additionalInfo: nil
            )
            specimens.append(specimen)
        }

        while (specimens.count > count) {
            specimens.removeLast()
        }

        return specimens
    }

    private func parseEntityImages() -> EntityImages {
        self.diaryImages?.compactMap { imageCandidate in
                imageCandidate as? DiaryImage
            }
            .toEntityImages()
            ?? EntityImages(remoteImageIds: [], localImages: [])
    }
}

extension RiistaSpecimen {
    func toCommonHarvestSpecimen() -> CommonHarvestSpecimen {
        return CommonHarvestSpecimen(
            id: remoteId?.toKotlinLong(),
            rev: rev?.toKotlinInt(),
            gender: RiistaCommon.Gender.Companion.shared.toBackendEnumCompat(value: gender),
            age: RiistaCommon.GameAge.Companion.shared.toBackendEnumCompat(value: age),
            weight: weight?.doubleValue.toKotlinDouble(),
            weightEstimated: weightEstimated?.doubleValue.toKotlinDouble(),
            weightMeasured: weightMeasured?.doubleValue.toKotlinDouble(),
            fitnessClass: RiistaCommon.GameFitnessClass.Companion.shared.toBackendEnumCompat(value: fitnessClass),
            antlersLost: antlersLost?.boolValue.toKotlinBoolean(),
            antlersType: RiistaCommon.GameAntlersType.Companion.shared.toBackendEnumCompat(value: antlersType),
            antlersWidth: antlersWidth?.toKotlinInt(),
            antlerPointsLeft: antlerPointsLeft?.toKotlinInt(),
            antlerPointsRight: antlerPointsRight?.toKotlinInt(),
            antlersGirth: antlersGirth?.toKotlinInt(),
            antlersLength: antlersLength?.toKotlinInt(),
            antlersInnerWidth: antlersInnerWidth?.toKotlinInt(),
            antlerShaftWidth: antlersShaftWidth?.toKotlinInt(),
            notEdible: notEdible?.boolValue.toKotlinBoolean(),
            alone: alone?.boolValue.toKotlinBoolean(),
            additionalInfo: additionalInfo
        )
    }

    @discardableResult
    func updateWithCommonSpecimen(specimen: CommonHarvestSpecimen) -> RiistaSpecimen {
        self.remoteId = specimen.id
        self.rev = specimen.rev
        self.gender = specimen.gender?.rawBackendEnumValue
        self.age = specimen.age?.rawBackendEnumValue
        self.weight = specimen.weight
        self.weightEstimated = specimen.weightEstimated
        self.weightMeasured = specimen.weightMeasured
        self.fitnessClass = specimen.fitnessClass?.rawBackendEnumValue
        self.antlersLost = specimen.antlersLost
        self.antlersType = specimen.antlersType?.rawBackendEnumValue
        self.antlersWidth = specimen.antlersWidth
        self.antlerPointsLeft = specimen.antlerPointsLeft
        self.antlerPointsRight = specimen.antlerPointsRight
        self.antlersGirth = specimen.antlersGirth
        self.antlersLength = specimen.antlersLength
        self.antlersInnerWidth = specimen.antlersInnerWidth
        self.antlersShaftWidth = specimen.antlerShaftWidth
        self.notEdible = specimen.notEdible
        self.alone = specimen.alone
        self.additionalInfo = specimen.additionalInfo

        return self
    }
}

extension Array where Element == CommonHarvestSpecimen {
    func toHarvestSpecimens(context: NSManagedObjectContext) -> NSOrderedSet {
        let harvestSpecimens = NSMutableOrderedSet()

        self.forEach { specimen in
            harvestSpecimens.add(specimen.toHarvestSpecimen(context: context))
        }

        return harvestSpecimens
    }
}

extension CommonHarvest {
    func toDiaryEntry(context: NSManagedObjectContext) -> DiaryEntry {
        let entity = NSEntityDescription.entity(forEntityName: "DiaryEntry", in: context)!
        let harvestEntry = DiaryEntry(entity: entity, insertInto: context)
        harvestEntry.type = DiaryEntryTypeHarvest

        return harvestEntry.updateWithCommonHarvest(harvest: self, context: context)
    }
}

extension CommonHarvestSpecimen {
    func toHarvestSpecimen(context: NSManagedObjectContext) -> RiistaSpecimen {
        let entity = NSEntityDescription.entity(forEntityName: "Specimen", in: context)!
        let harvestSpecimen = RiistaSpecimen(entity: entity, insertInto: context)

        return harvestSpecimen.updateWithCommonSpecimen(specimen: self)
    }
}

