import Foundation
import RiistaCommon

class AppHarvestPermitProvider: HarvestPermitProvider {

    func getPermit(permitNumber: String) -> CommonHarvestPermit? {
        guard let permit = RiistaPermitManager.sharedInstance().getPermit(permitNumber) else {
            return nil
        }

        return permit.toCommonHarvestPermit()
    }
}
