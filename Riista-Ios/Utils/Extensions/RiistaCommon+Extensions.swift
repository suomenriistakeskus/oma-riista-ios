import Foundation
import RiistaCommon

// Extensions to various RiistaCommon classes

extension ETRMSGeoLocation {
    func toCoordinate() -> CLLocationCoordinate2D {
        let wgs84Pair = RiistaMapUtils.sharedInstance().etrmStoWGS84(Int(latitude), y: Int(longitude))!
        return CLLocationCoordinate2D(latitude: wgs84Pair.x, longitude: wgs84Pair.y)
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
}

extension Coordinate {
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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
}

extension Int {
    func toKotlinInt() -> KotlinInt {
        KotlinInt(integerLiteral: self)
    }
}

extension Double {
    func toKotlinDouble() -> KotlinDouble {
        KotlinDouble(floatLiteral: self)
    }
}
