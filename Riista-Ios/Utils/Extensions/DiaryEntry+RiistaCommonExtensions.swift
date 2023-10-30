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

        let specimens = parseCommonSpecimens()

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
            modified: sent?.boolValue == false && pendingOperation?.intValue != DiaryEntryOperationDelete,
            deleted: pendingOperation?.intValue == DiaryEntryOperationDelete,
            images: parseEntityImages(),
            specimens: specimens,
            amount: amount?.int32Value ?? Int32(specimens.count),
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
            greySealHuntingMethod: RiistaCommon.GreySealHuntingMethod.Companion.shared.toBackendEnumCompat(value: huntingMethod),
            actorInfo: GroupHuntingPerson.Unknown(),
            selectedClub: nil
        )
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
}

