import Foundation
import RiistaCommon

class SpeciesInformationResolver: SpeciesResolver {
    func getSpeciesName(speciesCode: Int32) -> String? {
        let species = getSpecies(speciesCode: speciesCode)
        return RiistaUtils.name(withPreferredLanguage: species?.name)
    }

    func getMultipleSpecimensAllowedOnHarvests(speciesCode: Int32) -> Bool {
        let species = getSpecies(speciesCode: speciesCode)
        return species?.multipleSpecimenAllowedOnHarvests == true
    }

    private func getSpecies(speciesCode: Int32) -> RiistaSpecies? {
        return RiistaGameDatabase.sharedInstance()?.species(byId: Int(speciesCode))
    }
}
