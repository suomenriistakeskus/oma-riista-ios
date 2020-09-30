import Foundation

struct DatetimeUtil {
    private static let dateFormatter = DateFormatter(safeLocale:())!
    private static let ISO_8601 = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    private static let PLAIN_DATE = "yyyy-MM-dd"
    private static let DISPLAY_DATE = "d.M.yyyy"

    static func huntingYearContaining(date: Date) -> Int {
        let month = Calendar.current.component(.month, from: date)
        let year = Calendar.current.component(.year, from: date)

        return month > AppConstants.HuntingYearStartMonth ? year : year - 1;
    }

    static func dateToFormattedString(date: Date) -> String {
        dateFormatter.dateFormat = ISO_8601
        return dateFormatter.string(from: date)
    }

    static func dateToFormattedStringNoTime(date: Date) -> String {
        dateFormatter.dateFormat = DISPLAY_DATE
        return dateFormatter.string(from: date)
    }

    static func stringToNSDate(string: String?) -> NSDate? {
        if (string == nil) {
            return nil
        }

        dateFormatter.dateFormat = PLAIN_DATE
        return dateFormatter.date(from: string!)! as NSDate?
    }

    static func stringDateToDisplayString(string: String?) -> String {
        if (string == nil) {
            return ""
        }

        dateFormatter.dateFormat = PLAIN_DATE
        guard let date = dateFormatter.date(from: string!) else { return "" }

        dateFormatter.dateFormat = DISPLAY_DATE
        return dateFormatter.string(from: date)
    }

    static func seasonStartFor(startYear: Int) -> NSDate {
        var components = DateComponents()
        components.year = startYear
        components.month = 8
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        return Calendar.current.date(from: components)! as NSDate
    }

    static func seasonEndFor(startYear: Int) -> NSDate {
        var components = DateComponents()
        components.year = startYear + 1
        components.month = 8
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        let startOfNext = Calendar.current.date(from: components)

        return startOfNext!.addingTimeInterval(-1) as NSDate
    }

    static func yearStartFor(year:Int) -> NSDate {
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        return Calendar.current.date(from: components)! as NSDate
    }

    static func yearEndFor(year:Int) -> NSDate {
        var components = DateComponents()
        components.year = year + 1
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        let startOfNext = Calendar.current.date(from: components)

        return startOfNext!.addingTimeInterval(-1) as NSDate
    }
}
