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

    @discardableResult
    func updateWithCommonObservation(observation: CommonObservation, context: NSManagedObjectContext) -> ObservationEntry {
        self.remoteId = observation.remoteId
        self.rev = observation.revision
        self.mobileClientRefId = observation.mobileClientRefId
        self.observationSpecVersion = observation.observationSpecVersion.toNSNumber()
        self.gameSpeciesCode = observation.species.toGameSpeciesCode()

        self.observationCategory = observation.observationCategory.rawBackendEnumValue
        self.observationType = observation.observationType.rawBackendEnumValue
        self.deerHuntingType = observation.deerHuntingType.rawBackendEnumValue
        self.deerHuntingTypeDescription = observation.deerHuntingOtherTypeDescription

        self.coordinates = observation.location.toGeoCoordinate(context: context, existingCoordinates: self.coordinates)

        self.pointOfTime = observation.pointOfTime.toFoundationDate()
        self.year = observation.pointOfTime.year.toNSNumber()
        self.month = observation.pointOfTime.monthNumber.toNSNumber()

        self.diarydescription = observation.description_ ?? ""
        self.diaryImages = observation.images.toDiaryImages(context: context, existingImages: self.diaryImages)

        self.totalSpecimenAmount = observation.totalSpecimenAmount
        self.specimens = observation.specimens?.toObservationSpecimens(context: context)

        self.canEdit = NSNumber(value: observation.canEdit)
        self.mooselikeMaleAmount = observation.mooselikeMaleAmount
        self.mooselikeFemaleAmount = observation.mooselikeFemaleAmount
        self.mooselikeFemale1CalfAmount = observation.mooselikeFemale1CalfAmount
        self.mooselikeFemale2CalfsAmount = observation.mooselikeFemale2CalfsAmount
        self.mooselikeFemale3CalfsAmount = observation.mooselikeFemale3CalfsAmount
        self.mooselikeFemale4CalfsAmount = observation.mooselikeFemale4CalfsAmount
        self.mooselikeCalfAmount = observation.mooselikeCalfAmount
        self.mooselikeUnknownSpecimenAmount = observation.mooselikeUnknownSpecimenAmount

        self.observerName = observation.observerName
        self.observerPhoneNumber = observation.observerPhoneNumber
        self.officialAdditionalInfo = observation.officialAdditionalInfo
        self.verifiedByCarnivoreAuthority = observation.verifiedByCarnivoreAuthority
        self.inYardDistanceToResidence = observation.inYardDistanceToResidence

        self.litter = observation.litter
        self.pack = observation.pack

        return self
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

    @discardableResult
    func updateWithCommonSpecimen(specimen: CommonObservationSpecimen) -> ObservationSpecimen {
        self.remoteId = specimen.remoteId
        self.rev = specimen.revision
        self.gender = specimen.gender.rawBackendEnumValue
        self.age = specimen.age.rawBackendEnumValue
        self.state = specimen.stateOfHealth.rawBackendEnumValue
        self.marking = specimen.marking.rawBackendEnumValue
        self.widthOfPaw = specimen.widthOfPaw?.toDecimalNumber()
        self.lengthOfPaw = specimen.lengthOfPaw?.toDecimalNumber()

        return self
    }
}

extension Array where Element == CommonObservationSpecimen {
    func toObservationSpecimens(context: NSManagedObjectContext) -> NSOrderedSet {
        let observationSpecimens = NSMutableOrderedSet()

        self.forEach { specimen in
            observationSpecimens.add(specimen.toObservationSpecimen(context: context))
        }

        return observationSpecimens
    }
}

extension CommonObservation {
    func toObservationEntry(context: NSManagedObjectContext) -> ObservationEntry {
        let entity = NSEntityDescription.entity(forEntityName: "ObservationEntry", in: context)!
        let observationEntry = ObservationEntry(entity: entity, insertInto: context)
        observationEntry.type = DiaryEntryTypeObservation

        return observationEntry.updateWithCommonObservation(observation: self, context: context)
    }
}

extension CommonObservationSpecimen {
    func toObservationSpecimen(context: NSManagedObjectContext) -> ObservationSpecimen {
        let entity = NSEntityDescription.entity(forEntityName: "ObservationSpecimen", in: context)!
        let observationSpecimen = ObservationSpecimen(entity: entity, insertInto: context)

        return observationSpecimen.updateWithCommonSpecimen(specimen: self)
    }
}
