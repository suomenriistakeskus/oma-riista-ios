import Foundation

struct SpeciesUtils {
    static func isMoose(speciesCode: Int) -> Bool {
        return speciesCode == AppConstants.SpeciesCode.Moose
    }

    static func isDeer(speciesCode: Int) -> Bool {
        return speciesCode == AppConstants.SpeciesCode.FallowDeer ||
            speciesCode == AppConstants.SpeciesCode.WhiteTailedDeer ||
            speciesCode == AppConstants.SpeciesCode.WildForestDeer
    }

    static func isMooseOrDeerRequiringPermitForHunting(speciesCode: Int) -> Bool {
        return isMoose(speciesCode: speciesCode) || isDeer(speciesCode: speciesCode)
    }
}
