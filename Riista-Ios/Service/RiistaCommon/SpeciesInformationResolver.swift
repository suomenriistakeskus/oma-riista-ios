import Foundation
import RiistaCommon

class SpeciesInformationResolver: SpeciesResolver {
    func getSpeciesName(speciesCode: Int32) -> String? {
        let species = RiistaGameDatabase.sharedInstance()?.species(byId: Int(speciesCode))
        return RiistaUtils.name(withPreferredLanguage: species?.name)
    }
}
