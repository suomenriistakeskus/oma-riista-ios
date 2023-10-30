import Foundation
import RiistaCommon

extension CommonShootingTestParticipantDetailed {
    var formattedFullNameLastFirst: String {
        return String(
            format: "%@%@",
            self.lastName ?? "",
            self.firstName?.prefixed(with: " ") ?? ""
        )
    }
}
