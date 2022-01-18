import Foundation

@objc class AntlerInstructions: NSObject {

    @objc class func getInstructionsFor(speciesCode: Int) -> [Instructions] {
        switch speciesCode {
        case AppConstants.SpeciesCode.Moose:
            return getInstructionsForMoose()
        case AppConstants.SpeciesCode.WhiteTailedDeer:
            return getInstructionsForWhiteTailedDeer()
        case AppConstants.SpeciesCode.RoeDeer:
            return getInstructionsForRoeDeer()
        default:
            break
        }

        return []
    }

    private class func getInstructionsForMoose() -> [Instructions] {
        return [
            Instructions(
                titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsTitleAntlersWidth"),
                detailsText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsAntlersWidthMoose"),
                image: UIImage(named: "moose_antlers_width")),
            Instructions(
                titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsTitleAntlersGirth"),
                detailsText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsAntlersGirthDetails"),
                image: UIImage(named: "moose_antlers_girth"))
        ]
    }

    private class func getInstructionsForWhiteTailedDeer() -> [Instructions] {
        return [
            Instructions(
                titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsTitleAntlersGirth"),
                detailsText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsAntlersGirthDetails"),
                image: UIImage(named: "white_tailed_deer_antlers_girth")),
            Instructions(
                titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsTitleAntlersLength"),
                detailsText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsAntlersLengthDetails"),
                image: UIImage(named: "white_tailed_deer_antlers_length")),
            Instructions(
                titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsTitleAntlersInnerWidth"),
                detailsText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsAntlersInnerWidthWhiteTailedDeer"),
                image: UIImage(named: "white_tailed_deer_antlers_inner_width"))
        ]
    }

    private class func getInstructionsForRoeDeer() -> [Instructions] {
        return [
            Instructions(
                titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsTitleAntlersLength"),
                detailsText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsAntlersLengthDetails"),
                image: UIImage(named: "roe_deer_antlers_length")),
            Instructions(
                titleText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsTitleAntlerShaftDiameter"),
                detailsText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "InstructionsAntlerShaftDiameterRoeDeer"),
                image: UIImage(named: "roe_deer_antlers_shaft_width"))
        ]
    }
}

