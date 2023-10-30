import Foundation
import RiistaCommon

@objcMembers class CreateHarvestViewControllerHelper : NSObject {
    class func createViewController() -> UIViewController {
        return CreateHarvestViewController(initialSpeciesCode: nil)
    }

    class func createViewController(species: RiistaSpecies) -> UIViewController {
        return CreateHarvestViewController(initialSpeciesCode: species.speciesId)
    }
}

class CreateHarvestViewController :
    ModifyHarvestViewController<CreateHarvestController>,
    LocationListener {

    private lazy var _controller: CreateHarvestController = {
        let controller = CreateHarvestController(
            harvestSeasons: RiistaSDK.shared.harvestSeasons,
            harvestContext: RiistaSDK.shared.harvestContext,
            harvestPermitProvider: appHarvestPermitProvider,
            selectableHuntingClubs: RiistaSDK.shared.huntingClubsSelectableForEntriesFactory.create(),
            languageProvider: CurrentLanguageProvider(),
            preferences: RiistaSDK.shared.preferences,
            speciesResolver: SpeciesInformationResolver(),
            stringProvider: LocalizedStringProvider()
        )
        controller.modifyHarvestActionHandler = self
        controller.initialSpeciesCode = initialSpeciesCode?.toKotlinInt()

        return controller
    }()

    override var controller: CreateHarvestController {
        get {
            _controller
        }
    }

    /**
     * A location manager for updating the harvest location if needed.
     */
    private let locationManager = LocationManager()

    let initialSpeciesCode: Int?

    init(initialSpeciesCode: Int?) {
        self.initialSpeciesCode = initialSpeciesCode
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (controller.canMoveHarvestToCurrentUserLocation()) {
            locationManager.addListener(self)
            locationManager.start()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        locationManager.removeListener(self)
    }

    override func navigateToNextViewAfterSaving(harvest: CommonHarvest) {
        if let harvestId = harvest.localId?.int64Value {
            let viewHarvestViewController = ViewHarvestViewController(harvestId: harvestId)
            navigationController?.replaceViewController(
                viewControllerToPop: self,
                childViewControllers: [viewHarvestViewController],
                animated: true
            )
        } else {
            // just pop the navigation controller as we're unable to display harvest
            navigationController?.popViewController(animated: true)
        }
    }

    override func getViewTitle() -> String {
        "Loggame".localized()
    }

    func onLocationChanged(newLocation: CLLocation?) {
        guard let etrsLocation = newLocation?.coordinate.toETRSCoordinate(source: .manual) else {
            return
        }

        let locationChanged = controller.tryMoveHarvestToCurrentUserLocation(location: etrsLocation)
        if (!locationChanged) {
            locationManager.removeListener(self, stopIfLastListener: true)
        }
    }
}
