import Foundation
import RiistaCommon

class AppPermitProvider: PermitProvider {

    func getPermit(permitNumber: String) -> CommonPermit? {
        guard let permit = RiistaPermitManager.sharedInstance().getPermit(permitNumber) else {
            return nil
        }

        return permit.toCommonPermit()
    }
}
