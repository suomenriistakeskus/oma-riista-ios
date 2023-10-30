import Foundation
import RiistaCommon

extension CommonShootingTestParticipant {
    private static func currencyFormatter() -> NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale(identifier: "fi-FI")
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2

        return numberFormatter
    }

    func attemptSummaryFor(type shootingTestType: ShootingTestType) -> CommonShootingTestParticipantAttempt? {
        return self.attempts.first(where: { attempt in
            shootingTestType == attempt.type.value
        })
    }


    var formattedFullNameFirstLast: String {
        return String(
            format: "%@%@",
            self.firstName ?? "",
            self.lastName?.prefixed(with: " ") ?? ""
        )
    }

    var formattedFullNameLastFirst: String {
        return String(
            format: "%@%@",
            self.lastName ?? "",
            self.firstName?.prefixed(with: " ") ?? ""
        )
    }


    // MARK: Paid amounts

    var formattedTotalDueAmount: String {
        return Self.currencyFormatter().string(from: totalDueAmount.toDecimalNumber()) ?? ""
    }

    var formattedPaidAmount: String {
        return Self.currencyFormatter().string(from: paidAmount.toDecimalNumber()) ?? ""
    }

    var formattedRemainingAmount: String {
        return Self.currencyFormatter().string(from: remainingAmount.toDecimalNumber()) ?? ""
    }

    func formatRemainingAmount(newPaidAmount: Int64) -> String {
        let newRemainingAmount = totalDueAmount - Double(integerLiteral: newPaidAmount)
        return formatAmount(amount: newRemainingAmount)
    }

    func formatAmount(amount: Int64) -> String {
        formatAmount(amount: Double(integerLiteral: amount))
    }

    func formatAmount(amount: Double) -> String {
        return Self.currencyFormatter().string(from: amount.toDecimalNumber()) ?? ""
    }
}
