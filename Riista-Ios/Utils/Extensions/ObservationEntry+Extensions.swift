import Foundation
import RiistaCommon
import CoreData

extension ObservationEntry {

    func toCommonObservation(objectId: NSManagedObjectID) -> CommonObservation? {
        guard let dateTime = pointOfTime?.toLocalDateTime(),
              let location = coordinates?.toWGS84Coordinate().toETRSCoordinate(source: coordinates?.source ?? "") else {
                print("returning nil")
                return nil
        }

        return CommonObservation(
            localId: nil,
            localUrl: objectId.uriRepresentation().absoluteString,
            remoteId: remoteId?.toKotlinLong(),
            revision: rev?.toKotlinLong(),
            mobileClientRefId: mobileClientRefId?.toKotlinLong(),
            observationSpecVersion: observationSpecVersion?.int32Value ?? RiistaCommon.Constants.shared.OBSERVATION_SPEC_VERSION,
            species: gameSpeciesCode?.toSpecies() ?? Species.Unknown(),

            observationCategory: RiistaCommon.ObservationCategory.Companion.shared.toBackendEnumCompat(value: observationCategory),
            observationType: ObservationType.Companion.shared.toBackendEnumCompat(value: observationType),
            deerHuntingType: RiistaCommon.DeerHuntingType.Companion.shared.toBackendEnumCompat(value: deerHuntingType),
            deerHuntingOtherTypeDescription: deerHuntingTypeDescription,

            location: location,
            pointOfTime: dateTime,
            description: diarydescription,
            images: parseEntityImages(),

            totalSpecimenAmount: totalSpecimenAmount?.toKotlinInt(),
            specimens: parseCommonSpecimens(),
            canEdit: canEdit?.boolValue ?? false,
            modified: sent?.boolValue == false && pendingOperation?.intValue != DiaryEntryOperationDelete,
            deleted: pendingOperation?.intValue == DiaryEntryOperationDelete,

            mooselikeMaleAmount: mooselikeMaleAmount?.toKotlinInt(),
            mooselikeFemaleAmount: mooselikeFemaleAmount?.toKotlinInt(),
            mooselikeFemale1CalfAmount: mooselikeFemale1CalfAmount?.toKotlinInt(),
            mooselikeFemale2CalfsAmount: mooselikeFemale2CalfsAmount?.toKotlinInt(),
            mooselikeFemale3CalfsAmount: mooselikeFemale3CalfsAmount?.toKotlinInt(),
            mooselikeFemale4CalfsAmount: mooselikeFemale4CalfsAmount?.toKotlinInt(),
            mooselikeCalfAmount: mooselikeCalfAmount?.toKotlinInt(),
            mooselikeUnknownSpecimenAmount: mooselikeUnknownSpecimenAmount?.toKotlinInt(),

            observerName: observerName,
            observerPhoneNumber: observerPhoneNumber,
            officialAdditionalInfo: officialAdditionalInfo,
            verifiedByCarnivoreAuthority: verifiedByCarnivoreAuthority?.toKotlinBoolean(),

            inYardDistanceToResidence: inYardDistanceToResidence?.toKotlinInt(),
            litter: litter?.toKotlinBoolean(),
            pack: pack?.toKotlinBoolean()
        )
    }


    private func parseCommonSpecimens() -> [CommonObservationSpecimen]? {
        guard let specimens = specimens else {
            return nil
        }

        var commonSpecimens = specimens.compactMap { specimen in
            (specimen as? ObservationSpecimen)?.toCommonObservationSpecimen()
        }

        return ensureSpecimenCount(specimens: &commonSpecimens, count: totalSpecimenAmount?.intValue ?? specimens.count)
    }

    private func ensureSpecimenCount(specimens: inout [CommonObservationSpecimen], count: Int) -> [CommonObservationSpecimen] {
        while (specimens.count < count) {
            let specimen = CommonObservationSpecimen(
                remoteId: nil,
                revision: nil,
                gender: RiistaCommon.Gender.Companion.shared.toBackendEnumCompat(value: nil),
                age: RiistaCommon.GameAge.Companion.shared.toBackendEnumCompat(value: nil),
                stateOfHealth: ObservationSpecimenState.Companion.shared.toBackendEnumCompat(value: nil),
                marking: ObservationSpecimenMarking.Companion.shared.toBackendEnumCompat(value: nil),
                widthOfPaw: nil,
                lengthOfPaw: nil
            )
            specimens.append(specimen)
        }

        while (specimens.count > count) {
            specimens.removeLast()
        }

        return specimens
    }

    private func parseEntityImages() -> EntityImages {
        self.diaryImages?.array
            .compactMap { imageCandidate in
                imageCandidate as? DiaryImage
            }
            .toEntityImages()
            ?? EntityImages(remoteImageIds: [], localImages: [])
    }
}

extension ObservationSpecimen {
    func toCommonObservationSpecimen() -> CommonObservationSpecimen {
        return CommonObservationSpecimen(
            remoteId: remoteId?.toKotlinLong(),
            revision: rev?.toKotlinInt(),
            gender: RiistaCommon.Gender.Companion.shared.toBackendEnumCompat(value: gender),
            age: RiistaCommon.GameAge.Companion.shared.toBackendEnumCompat(value: age),
            stateOfHealth: ObservationSpecimenState.Companion.shared.toBackendEnumCompat(value: state),
            marking: ObservationSpecimenMarking.Companion.shared.toBackendEnumCompat(value: marking),
            widthOfPaw: widthOfPaw?.doubleValue.toKotlinDouble(),
            lengthOfPaw: lengthOfPaw?.doubleValue.toKotlinDouble()
        )
    }
}

extension CommonObservation {
    var mooselikeSpecimenAmount: Int {
        return
            (1) * (mooselikeMaleAmount?.intValue ?? 0) +
            (1) * (mooselikeFemaleAmount?.intValue ?? 0) +
            (1 + 1) * (mooselikeFemale1CalfAmount?.intValue ?? 0) +
            (1 + 2) * (mooselikeFemale2CalfsAmount?.intValue ?? 0) +
            (1 + 3) * (mooselikeFemale3CalfsAmount?.intValue ?? 0) +
            (1 + 4) * (mooselikeFemale4CalfsAmount?.intValue ?? 0) +
            (1) * (mooselikeCalfAmount?.intValue ?? 0) +
            (1) * (mooselikeUnknownSpecimenAmount?.intValue ?? 0)
    }
}
