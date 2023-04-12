import Foundation

class MonthNameFormatter {
    private static let monthNameFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = RiistaUtils.appLocale()
        dateFormatter.dateFormat = "LLLL"
        return dateFormatter
    }()

    static func formatMonthName(date: Date?) -> String? {
        guard let date = date else {
            return nil
        }

        let appLocale = RiistaUtils.appLocale()
        monthNameFormatter.locale = appLocale

        return monthNameFormatter.string(from: date).capitalized(with: appLocale)
    }
}
