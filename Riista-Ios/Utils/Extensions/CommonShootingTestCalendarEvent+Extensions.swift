import Foundation
import RiistaCommon

extension CommonShootingTestCalendarEvent {
    private static func currencyFormatter() -> NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale(identifier: "fi-FI")
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2

        return numberFormatter
    }


    // MARK: Date and time

    var formattedDate: String {
        self.date?.toFoundationDate().formatDateOnly() ?? ""
    }

    var formattedBeginTime: String {
        self.beginTime?.toFoundationDate().formatTime() ?? ""
    }

    var formattedEndTime: String? {
        self.endTime?.toFoundationDate().formatTime()
    }

    // Includes both begin and end time
    var formattedTime: String {
        if let endTime = self.formattedEndTime {
            return "\(self.formattedBeginTime) - \(endTime)"
        } else {
            return self.formattedBeginTime
        }
    }

    var formattedDateAndTime: String {
        "\(formattedDate) \(formattedTime)"
    }


    // MARK: Paid amounts

    var formattedTotalPaidAmount: String {
        let amount = self.totalPaidAmount?.toDecimalNumber() ?? 0.0
        return Self.currencyFormatter().string(from: amount) ?? ""
    }
}
