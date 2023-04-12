import Foundation
import MaterialComponents
import RiistaCommon

@objc class MyGameQuickButtonsHelper: NSObject {
    private static let QUICK_BUTTON_COUNT = 2
    private static let TITLE_DEFAULT: String = "-"

    private let observationDefaultPrimary = AppConstants.SpeciesCode.Moose
    private let observationDefaultSecondary = AppConstants.SpeciesCode.WhiteTailedDeer

    private weak var navigationController: UINavigationController?


    @objc init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
        super.init()
    }

    @objc func setupObservationButtons(button1: UIButton, button2: UIButton) {
        let buttons = [button1, button2]
        let latestSpecies = fetchLatestObservationSpecies()

        for (buttonIndex, button) in buttons.enumerated() {
            setupButton(
                button: button,
                species: latestSpecies.getOrNil(index: buttonIndex),
                clickAction: #selector(onObservationButtonClicked(button:))
            )
        }
    }

    private func setupButton(button: UIButton, species: RiistaSpecies?, clickAction: Selector) {
        let title: String
        if let speciesName = species?.name {
            title = RiistaUtils.name(withPreferredLanguage: speciesName) ?? "-"
        } else {
            title = "-"
        }

        button.titleLabel?.lineBreakMode = .byWordWrapping;
        button.titleLabel?.textAlignment = .center;
        button.setTitle(title, for: .normal)
        button.speciesCode = species?.speciesId
        button.addTarget(self, action: clickAction, for: .touchUpInside)
    }

    @objc private func onObservationButtonClicked(button: UIButton) {
        let initialSpeciesCode = button.speciesCode

        let viewController = CreateObservationViewController(initialSpeciesCode: initialSpeciesCode)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func fetchLatestObservationSpecies() -> [RiistaSpecies] {
        var species: [RiistaSpecies] = RiistaSDK.shared.observationContext
            .getLatestObservationSpecies(size: Int32(Self.QUICK_BUTTON_COUNT))
            .compactMap { species in
                guard let speciesCode = species.knownSpeciesCodeOrNull()?.intValue else {
                    return nil
                }

                return RiistaGameDatabase.sharedInstance().species(byId: speciesCode)
            }

        if (species.count < Self.QUICK_BUTTON_COUNT) {
            species.appendSpeciesIfDoesntExist(speciesCode: observationDefaultPrimary)
        }

        if (species.count < Self.QUICK_BUTTON_COUNT) {
            species.appendSpeciesIfDoesntExist(speciesCode: observationDefaultSecondary)
        }

        return species
    }
}

fileprivate extension Array where Element == RiistaSpecies {
    mutating func appendSpeciesIfDoesntExist(speciesCode: Int) {
        if (contains(where: { $0.speciesId == speciesCode })) {
            // species exists
            return
        }

        if let species = RiistaGameDatabase.sharedInstance().species(byId: speciesCode) {
            append(species)
        }
    }
}

fileprivate extension UIButton {
    var speciesCode: Int? {
        get {
            if (tag > 0) {
                return tag
            } else {
                return nil
            }
        }
        set(value) {
            if let value = value {
                tag = value
            } else {
                tag = -1
            }
        }
    }
}
