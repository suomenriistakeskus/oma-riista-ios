import Foundation
import RiistaCommon
import CoreData

extension SrvaEntry {

    func toSrvaEvent(objectId: NSManagedObjectID) -> CommonSrvaEvent? {
        guard let dateTime = pointOfTime?.toLocalDateTime(),
              let location = coordinates?.toWGS84Coordinate().toETRSCoordinate(source: coordinates?.source ?? "") else {
                print("returning nil")
                return nil
        }

        return CommonSrvaEvent(
            localId: nil,
            localUrl: objectId.uriRepresentation().absoluteString,
            remoteId: remoteId?.toKotlinLong(),
            revision: rev?.toKotlinLong(),
            mobileClientRefId: mobileClientRefId?.toKotlinLong(),
            srvaSpecVersion: srvaEventSpecVersion?.int32Value ?? RiistaCommon.Constants.shared.SRVA_SPEC_VERSION,
            state: SrvaEventState.Companion.shared.toBackendEnumCompat(value: state),
            rhyId: rhyId?.toKotlinInt(),
            canEdit: canEdit?.boolValue ?? false,
            location: location,
            pointOfTime: dateTime,
            author: toCommonSrvaEventAuthor(),
            approver: toCommonSrvaEventApprover(),
            species: gameSpeciesCode?.toSpecies() ?? Species.Other(),
            otherSpeciesDescription: otherSpeciesDescription,
            specimens: parseCommonSpecimens(),
            eventCategory: SrvaEventCategoryType.Companion.shared.toBackendEnumCompat(value: eventName),
            deportationOrderNumber: deportationOrderNumber,
            eventType: SrvaEventType.Companion.shared.toBackendEnumCompat(value: eventType),
            otherEventTypeDescription: otherTypeDescription,
            eventTypeDetail: SrvaEventTypeDetail.Companion.shared.toBackendEnumCompat(value: eventTypeDetail),
            otherEventTypeDetailDescription: otherEventTypeDetailDescription,
            eventResult: SrvaEventResult.Companion.shared.toBackendEnumCompat(value: eventResult),
            eventResultDetail: SrvaEventResultDetail.Companion.shared.toBackendEnumCompat(value: eventResultDetail),
            methods: parseCommonSrvaMethods(),
            otherMethodDescription: otherMethodDescription,
            personCount: personCount?.int32Value ?? 0,
            hoursSpent: timeSpent?.int32Value ?? 0,
            description: descriptionText,
            images: parseEntityImages()
        )
    }

    private func toCommonSrvaEventAuthor() -> CommonSrvaEventAuthor? {
        guard let id = authorId, let rev = authorRev else {
            return nil
        }
        return CommonSrvaEventAuthor(
            id: id.int64Value,
            revision: rev.int64Value,
            byName: authorByName,
            lastName: authorLastName
        )
    }

    private func toCommonSrvaEventApprover() -> CommonSrvaEventApprover? {
        if (approverFirstName == nil && approverLastName == nil) {
            return nil
        } else {
            return CommonSrvaEventApprover(
                firstName: approverFirstName,
                lastName: approverLastName
            )
        }
    }

    private func parseCommonSrvaMethods() -> [CommonSrvaMethod] {
        let methods = parseMethods()
        let commonMethods = methods.map { (method) -> CommonSrvaMethod? in
            let srvaMethod = method as! SrvaMethod
            let commonSrvaMethod = SrvaMethodType.Companion.shared.toBackendEnumCompat(value: srvaMethod.name)
            return CommonSrvaMethod(
                type: commonSrvaMethod,
                selected: srvaMethod.isChecked.boolValue
            )
        }
        return commonMethods.compactMap{ $0 }
    }

    private func parseCommonSpecimens() -> [CommonSrvaSpecimen] {
        var commonSpecimens = [CommonSrvaSpecimen]()
        guard let specimenArray = specimens?.array else {
            return ensureSpecimenCount(specimens: &commonSpecimens, count: totalSpecimenAmount?.intValue ?? 1)
        }
        for specimen in specimenArray {
            let srvaSpecimen = specimen as! SrvaSpecimen
            let commonSpecimen = srvaSpecimen.toCommonSrvaSpecimen()
            commonSpecimens.append(commonSpecimen)
        }
        return ensureSpecimenCount(specimens: &commonSpecimens, count: totalSpecimenAmount?.intValue ?? 1)
    }

    private func ensureSpecimenCount(specimens: inout [CommonSrvaSpecimen], count: Int) -> [CommonSrvaSpecimen] {
        if (specimens.count < count) {
            for _ in 1...(count - specimens.count) {
                let specimen = CommonSrvaSpecimen(
                    gender: RiistaCommon.Gender.Companion.shared.toBackendEnumCompat(value: nil),
                    age: RiistaCommon.GameAge.Companion.shared.toBackendEnumCompat(value: nil)
                )
                specimens.append(specimen)
            }
        }
        if (specimens.count > count) {
            for _ in 1...(count - specimens.count) {
                specimens.removeLast()
            }
        }
        return specimens
    }

    private func parseEntityImages() -> EntityImages {
        var localImages = [EntityImage]()
        var remoteIds = [String]()
        guard let imageArray = diaryImages?.array else {
            return EntityImages(remoteImageIds: [String](), localImages: localImages)
        }
        for image in imageArray {
            let diaryImage = image as! DiaryImage
            if (diaryImage.type.intValue == DiaryImageTypeLocal) {
                let entityImage = EntityImage(
                    serverId: diaryImage.imageid,
                    localIdentifier: diaryImage.localIdentifier,
                    localUrl: diaryImage.uri,
                    status: .local
                )
                localImages.append(entityImage)
            } else if (diaryImage.type.intValue == DiaryImageTypeRemote && diaryImage.imageid != nil) {
                // it seems that latest images added to SRVA event are actually the first in the list
                // --> reverse the collection
                remoteIds.insert(diaryImage.imageid, at: 0)
            }
        }

        let entityImages = EntityImages(remoteImageIds: remoteIds, localImages: localImages)
        return entityImages
    }
}

extension SrvaSpecimen {
    func toCommonSrvaSpecimen() -> CommonSrvaSpecimen {
        return CommonSrvaSpecimen(
            gender: RiistaCommon.Gender.Companion.shared.toBackendEnumCompat(value: gender),
            age: RiistaCommon.GameAge.Companion.shared.toBackendEnumCompat(value: age)
        )
    }
}

extension CommonSrvaEvent {
    func toSrvaEntry(context: NSManagedObjectContext) -> SrvaEntry {

        let entity = NSEntityDescription.entity(forEntityName: "SrvaEntry", in: context)!
        let entry = SrvaEntry.init(entity: entity, insertInto: context)

        entry.type = DiaryEntryTypeSrva

        entry.remoteId = remoteId
        entry.rev = revision
        entry.mobileClientRefId = mobileClientRefId
        entry.srvaEventSpecVersion = srvaSpecVersion.toNSNumber()
        entry.state = state.rawBackendEnumValue
        entry.rhyId = rhyId
        entry.canEdit = NSNumber(value: canEdit)
        entry.coordinates = location.toGeoCoordinate(context: context, existingCoordinates: entry.coordinates)

        entry.pointOfTime = pointOfTime.toFoundationDate()
        entry.year = pointOfTime.year.toNSNumber()
        entry.month = pointOfTime.monthNumber.toNSNumber()

        entry.authorId = author?.id.toNSNumber()
        entry.authorRev = author?.revision.toNSNumber()
        entry.authorByName = author?.byName
        entry.authorLastName = author?.lastName

        entry.approverFirstName = approver?.firstName
        entry.approverLastName = approver?.lastName

        entry.gameSpeciesCode = species.toGameSpeciesCode()
        entry.otherSpeciesDescription = otherSpeciesDescription

        entry.addSpecimens(specimens.toSrvaSpecimens(context: context))
        entry.totalSpecimenAmount = NSNumber(value: specimens.count)

        entry.pendingOperation = NSNumber(value: DiaryEntryOperationNone)

        entry.eventName = eventCategory.rawBackendEnumValue
        entry.eventType = eventType.rawBackendEnumValue
        entry.otherTypeDescription = otherEventTypeDescription
        entry.eventResult = eventResult.rawBackendEnumValue
        entry.methods = methods.toMethodString()

        entry.otherMethodDescription = otherMethodDescription
        entry.personCount = personCount.toNSNumber()
        entry.timeSpent = hoursSpent.toNSNumber()
        entry.descriptionText = description_

        entry.deportationOrderNumber = deportationOrderNumber
        entry.eventTypeDetail = eventTypeDetail.rawBackendEnumValue
        entry.otherEventTypeDetailDescription = otherEventTypeDetailDescription
        entry.eventResultDetail = eventResultDetail.rawBackendEnumValue

        setImages(context: context, entry: entry)
        return entry
    }

    private func setImages(context: NSManagedObjectContext, entry: SrvaEntry) {
        let diaryImages = NSMutableOrderedSet()

        for entityImage in images.localImages {
            let diaryImage = entityImage.toDiaryImage(context: context)
            diaryImages.add(diaryImage)
        }
        for remoteId in images.remoteImageIds {
            let diaryImage = remoteId.toDiaryImage(context: context)
            diaryImages.add(diaryImage)
        }
        entry.addDiaryImages(diaryImages)
    }
}

extension Array where Element == CommonSrvaMethod {
    func toMethodString() -> String? {
        let eventMethods = NSMutableArray()
        for method in self {
            let dict:[String:Any] = ["name": method.type.rawBackendEnumValue ?? "", "isChecked": method.selected]
            eventMethods.add(dict)
        }
        return RiistaModelUtils.json(from: eventMethods)
    }
}

extension Array where Element == CommonSrvaSpecimen {
    func toSrvaSpecimens(context: NSManagedObjectContext) -> NSOrderedSet {
        let srvaSpecimens = NSMutableArray()
        let entity = NSEntityDescription.entity(forEntityName: "SrvaSpecimen", in: context)!

        for commonSpecimen in self {
            let srvaSpecimen = SrvaSpecimen.init(entity: entity, insertInto: context)
            srvaSpecimen.age = commonSpecimen.age.rawBackendEnumValue ?? nil
            srvaSpecimen.gender = commonSpecimen.gender.rawBackendEnumValue ?? nil
            srvaSpecimens.add(srvaSpecimen)
        }

        return NSOrderedSet(array: srvaSpecimens.copy() as! [Any])
    }
}

