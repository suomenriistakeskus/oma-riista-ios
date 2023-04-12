import Foundation
import RiistaCommon
import CoreData
import CoreLocation

// Extensions to various RiistaCommon classes

extension ETRMSGeoLocation {
    func toCoordinate() -> CLLocationCoordinate2D {
        let wgs84Pair = RiistaMapUtils.sharedInstance().etrmStoWGS84(Int(latitude), y: Int(longitude))!
        return CLLocationCoordinate2D(latitude: wgs84Pair.x, longitude: wgs84Pair.y)
    }

    func toGeoCoordinate(context: NSManagedObjectContext, existingCoordinates: GeoCoordinate?) -> GeoCoordinate {
        if let coordinates = existingCoordinates {
            return coordinates.updateWithCommonLocation(location: self)
        }

        let entity = NSEntityDescription.entity(forEntityName: "GeoCoordinate", in: context)!
        let coordinates = GeoCoordinate(entity: entity, insertInto: context)

        return coordinates.updateWithCommonLocation(location: self)
    }
}

extension CLLocationCoordinate2D {
    func toETRSCoordinate(source: GeoLocationSource) -> ETRMSGeoLocation {
        let etrsCoordinate = RiistaMapUtils.sharedInstance().wgs84toETRSTM35FIN(latitude, longitude: longitude)!
        return ETRMSGeoLocation(
            latitude: Int32(etrsCoordinate.x),
            longitude: Int32(etrsCoordinate.y),
            source: source.toBackendEnumCompat(),
            accuracy: nil,
            altitude: nil,
            altitudeAccuracy: nil
        )
    }

    func toETRSCoordinate(source: String) -> ETRMSGeoLocation {
        let geoSource = GeoLocationSource.Companion.shared.toBackendEnumCompat(value: source)
        return toETRSCoordinate(source: geoSource.value ?? .manual)
    }
}

extension Coordinate {
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension GeoCoordinate {
    func toWGS84Coordinate() -> CLLocationCoordinate2D {
        let wgs84Pair = RiistaMapUtils.sharedInstance().etrmStoWGS84(latitude.intValue, y: longitude.intValue)!
        return CLLocationCoordinate2D(latitude: wgs84Pair.x, longitude: wgs84Pair.y)
    }

    @discardableResult
    func updateWithCommonLocation(location: ETRMSGeoLocation) -> GeoCoordinate {
        self.latitude = location.latitude.toNSNumber()
        self.longitude = location.longitude.toNSNumber()
        self.source = location.source.rawBackendEnumValue

        return self
    }
}

extension LocalDate {
    func toFoundationDate() -> Foundation.Date {
        var dateComponents = DateComponents()
        dateComponents.year = Int(year)
        dateComponents.month = Int(monthNumber)
        dateComponents.day = Int(dayOfMonth)
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        dateComponents.nanosecond = 0

        return Calendar.current.date(from: dateComponents)!
    }
}

extension LocalDateTime {
    func toFoundationDate() -> Foundation.Date {
        var dateComponents = DateComponents()
        dateComponents.year = Int(year)
        dateComponents.month = Int(monthNumber)
        dateComponents.day = Int(dayOfMonth)
        dateComponents.hour = Int(hour)
        dateComponents.minute = Int(minute)
        dateComponents.second = Int(second)
        dateComponents.nanosecond = 0

        return Calendar.current.date(from: dateComponents)!
    }
}

extension LocalDateTime: Comparable {
    public static func == (lhs: LocalDateTime, rhs: LocalDateTime) -> Bool {
        return lhs.compareTo(other: rhs) == 0
    }

    public static func < (lhs: LocalDateTime, rhs: LocalDateTime) -> Bool {
        return lhs.compareTo(other: rhs) < 0
    }
}

extension LocalTime {
    func toFoundationDate() -> Foundation.Date {
        let calendar = Calendar.current
        var components = DateComponents()

        // getting .minute component from a Date that does not specify also the date produces
        // invalid result. This is probably caused by leap seconds (minutes?) and/or other changes
        // made in the past.
        //
        // since actual date is unknown here, let's use current date
        let now = Date()
        components.year = calendar.component(.year, from: now)
        components.month = calendar.component(.month, from: now)
        components.day = calendar.component(.day, from: now)

        components.hour = Int(self.hour)
        components.minute = Int(self.minute)
        components.second = Int(self.second)
        components.nanosecond = 0

        return calendar.date(from: components) ?? Date()
    }
}

extension Foundation.Date {
    func toLocalDate() -> LocalDate {
        let calendar = Calendar.current
        return LocalDate(
            year: Int32(calendar.component(.year, from: self)),
            monthNumber: Int32(calendar.component(.month, from: self)),
            dayOfMonth:  Int32(calendar.component(.day, from: self))
        )
    }

    func toLocalDateTime() -> LocalDateTime {
        let calendar = Calendar.current
        return LocalDateTime(
            year: Int32(calendar.component(.year, from: self)),
            monthNumber: Int32(calendar.component(.month, from: self)),
            dayOfMonth:  Int32(calendar.component(.day, from: self)),
            hour:  Int32(calendar.component(.hour, from: self)),
            minute:  Int32(calendar.component(.minute, from: self)),
            second:  Int32(calendar.component(.second, from: self))
        )
    }

    func toLocalTime() -> LocalTime {
        let calendar = Calendar.current
        return LocalTime(
            hour:  Int32(calendar.component(.hour, from: self)),
            minute:  Int32(calendar.component(.minute, from: self)),
            second:  Int32(calendar.component(.second, from: self))
        )
    }
}

extension Int {
    func toKotlinInt() -> KotlinInt {
        KotlinInt(integerLiteral: self)
    }

    func toSpecies() -> Species {
        if (self < 0) {
            return Species.Other()
        } else {
            return Species.Known(speciesCode: Int32(self))
        }
    }
}

extension Double {
    func toKotlinDouble() -> KotlinDouble {
        KotlinDouble(floatLiteral: self)
    }
}

extension Int32 {
    func toNSNumber() -> NSNumber {
        NSNumber(value: self)
    }

    func toKotlinInt() -> KotlinInt {
        KotlinInt(int: self)
    }
}

extension Int64 {
    func toKotlinLong() -> KotlinLong {
        KotlinLong(longLong: self)
    }

    func toNSNumber() -> NSNumber {
        NSNumber(value: self)
    }
}

extension Bool {
    func toKotlinBoolean() -> KotlinBoolean {
        KotlinBoolean(value: self)
    }

    func toNSNumber() -> NSNumber {
        NSNumber(booleanLiteral: self)
    }
}

extension NSNumber {
    func toSpecies() -> Species {
        if (self == -1) {
            return Species.Other()
        } else {
            return Species.Known(speciesCode: self.int32Value)
        }
    }

    func toKotlinBoolean() -> KotlinBoolean {
        boolValue.toKotlinBoolean()
    }

    func toKotlinInt() -> KotlinInt {
        intValue.toKotlinInt()
    }

    func toKotlinLong() -> KotlinLong {
        int64Value.toKotlinLong()
    }
}

extension KotlinDouble {
    func toDecimalNumber() -> NSDecimalNumber {
        NSDecimalNumber(value: self.doubleValue)
    }
}

extension Species {
    func toGameSpeciesCode() -> NSNumber? {
        if let known = self as? Species.Known {
            return known.speciesCode.toNSNumber()
        }
        return nil
    }
}

extension NSString {
    func toDiaryImage(context: NSManagedObjectContext) -> DiaryImage {
        let entity = NSEntityDescription.entity(forEntityName: "DiaryImage", in: context)!
        let diaryImage = DiaryImage.init(entity: entity, insertInto: context)
        diaryImage.type = NSNumber(value: DiaryImageTypeRemote)
        diaryImage.imageid = self as String
        return diaryImage
    }
}



extension Array where Element == DiaryImage {
    func toEntityImages() -> EntityImages {
        var entityImages = [EntityImage]()
        var remoteImageIds = [String]()

        self.forEach { diaryImage in
            let imageStatus: EntityImage.Status
            if (diaryImage.type.intValue == DiaryImageTypeLocal) {
                // local images may be newly added or added previously but marked for removal. Check
                // the status as the common lib also wishes to differentiate images marked for removal
                switch (diaryImage.status?.intValue ?? 0) {
                case DiaryImageStatusDeletion:
                    imageStatus = .localToBeRemoved
                case DiaryImageStatusInsertion: fallthrough
                case 0: fallthrough
                default:
                    imageStatus = .local
                }
            } else {
                imageStatus = .uploaded
            }

            let image = EntityImage(
                serverId: diaryImage.imageid,
                localIdentifier: diaryImage.localIdentifier,
                localUrl: diaryImage.uri,
                status: imageStatus
            )
            entityImages.append(image)

            if let remoteImageId = image.serverId, imageStatus == .uploaded {
                remoteImageIds.append(remoteImageId)
            }
        }

        return EntityImages(remoteImageIds: remoteImageIds, localImages: entityImages)
    }
}

extension DiaryImage {

    @discardableResult
    func updateWithEntityImage(image: EntityImage) -> DiaryImage {
        self.imageid = image.serverId
        self.localIdentifier = image.localIdentifier
        self.uri = image.localUrl

        if (image.status == .local) {
            self.type = NSNumber(value: DiaryImageTypeLocal)
            self.status = NSNumber(value: DiaryImageStatusInsertion)
        } else if (image.status == .localToBeRemoved) {
            self.type = NSNumber(value: DiaryImageTypeLocal)
            self.status = NSNumber(value: DiaryImageStatusDeletion)
        } else if (image.status == .uploaded) {
            self.type = NSNumber(value: DiaryImageTypeRemote)
            self.status = NSNumber(value: 0) // needs to be updated outside if this is removed
        }

        return self
    }

    static func createForRemoteImage(remoteImageId: String, context: NSManagedObjectContext) -> DiaryImage {
        let entity = NSEntityDescription.entity(forEntityName: "DiaryImage", in: context)!
        let diaryImage = DiaryImage.init(entity: entity, insertInto: context)
        diaryImage.type = NSNumber(value: DiaryImageTypeRemote)
        diaryImage.imageid = remoteImageId
        return diaryImage
    }
}

extension EntityImages {
    // naturally harvests store images in NSSet instead of NSOrderedSet..
    func toDiaryImages(context: NSManagedObjectContext, existingImages: Set<AnyHashable>?) -> NSSet {
        guard let existingImages = existingImages else {
            return []
        }

        let images = NSOrderedSet(array: Array(existingImages))
        let result = toDiaryImages(context: context, existingImages: images)
//        let resultSet = Set(arrayLiteral: result.map { $0 as? DiaryImage } )
        let resultSet = NSSet(array: result.array)
        return resultSet
    }

    func toDiaryImages(context: NSManagedObjectContext, existingImages: NSOrderedSet?) -> NSOrderedSet {
        let existingImages = existingImages?.compactMap { image in
            image as? DiaryImage
        } ?? []

        var newImages = localImages.filter { localImage in
            localImage.status == .local
        }

        // keep existing images if there are no new images
        if (newImages.isEmpty) {
            return NSOrderedSet(array: existingImages)
        }

        var resultImages: [DiaryImage] = existingImages.compactMap { existingImage in
            // keep the image if it is found in the new images
            let imageIndexInNewImages = newImages.firstIndex { newImage in
                newImage.serverId == existingImage.imageid
            }

            if let imageIndexInNewImages = imageIndexInNewImages {
                // images cannot be modified thus there is no need to update existing image
                newImages.remove(at: imageIndexInNewImages)
                return existingImage
            } else {
                // not found in new images. We've got two possibilities
                // 1. image was just added (not sent to backend yet) -> remove it
                // 2. image has been sent to backend -> mark for deletion
                if let existingImageStatus = existingImage.status?.intValue,
                    existingImageStatus == DiaryImageStatusInsertion {
                    return nil
                } else {
                    existingImage.status = NSNumber(value: DiaryImageStatusDeletion)
                    return existingImage
                }
            }
        }

        resultImages.append(contentsOf: newImages.map { newImage in
            newImage.toDiaryImage(context: context)
        })

        return NSOrderedSet(array: resultImages)
    }
}

extension EntityImage {
    func toDiaryImage(context: NSManagedObjectContext) -> DiaryImage {
        let entity = NSEntityDescription.entity(forEntityName: "DiaryImage", in: context)!
        let diaryImage = DiaryImage(entity: entity, insertInto: context)

        return diaryImage.updateWithEntityImage(image: self)
    }
}
