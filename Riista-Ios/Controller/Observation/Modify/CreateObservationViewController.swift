import Foundation
import RiistaCommon

@objcMembers class CreateObservationViewControllerHelper : NSObject {
    class func createViewController() -> UIViewController {
        return CreateObservationViewController(initialSpeciesCode: nil)
    }

    class func createViewController(species: RiistaSpecies) -> UIViewController {
        return CreateObservationViewController(initialSpeciesCode: species.speciesId)
    }
}

class CreateObservationViewController :
    ModifyObservationViewController<CreateObservationController>,
    LocationListener {

    private lazy var _controller: CreateObservationController = {
        let controller = CreateObservationController(
            userContext: RiistaSDK.shared.currentUserContext,
            observationContext: RiistaSDK.shared.observationContext,
            metadataProvider: RiistaSDK.shared.metadataProvider,
            stringProvider: LocalizedStringProvider()
        )

        controller.initialSpeciesCode = initialSpeciesCode?.toKotlinInt()

        return controller
    }()

    override var controller: CreateObservationController {
        get {
            _controller
        }
    }

    /**
     * A location manager for updating the observation location if needed.
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

        if (controller.canMoveObservationToCurrentUserLocation()) {
            locationManager.addListener(self)
            locationManager.start()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        locationManager.removeListener(self)
    }

    override func navigateToNextViewAfterSaving(observation: CommonObservation) {
        if let observationId = observation.localId?.int64Value {
            let viewObservationViewController = ViewObservationViewController(observationId: observationId)
            self.navigationController?.popViewController(animated: false)
            self.navigationController?.pushViewController(viewObservationViewController, animated: true)
        } else {
            // just pop the navigation controller as we're unable to display observation
            self.navigationController?.popViewController(animated: true)
        }
    }

    override func getViewTitle() -> String {
        "LogObservation".localized()
    }

    func onLocationChanged(newLocation: CLLocation?) {
        guard let etrsLocation = newLocation?.coordinate.toETRSCoordinate(source: .manual) else {
            return
        }

        let locationChanged = controller.tryMoveObservationToCurrentUserLocation(location: etrsLocation)
        if (!locationChanged) {
            locationManager.removeListener(self, stopIfLastListener: true)
        }
    }
}
