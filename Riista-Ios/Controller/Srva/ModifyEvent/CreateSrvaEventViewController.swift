import Foundation
import RiistaCommon

@objc class CreateSrvaEventViewControllerHelper : NSObject {
    @objc class func createViewController() -> UIViewController {
        return CreateSrvaEventViewController()
    }
}

class CreateSrvaEventViewController :
    ModifySrvaEventViewController<CreateSrvaEventController>,
    LocationListener {

    private lazy var _controller: RiistaCommon.CreateSrvaEventController = {
        RiistaCommon.CreateSrvaEventController(
            metadataProvider: RiistaSDK.shared.metadataProvider,
            srvaContext: RiistaSDK.shared.srvaContext,
            stringProvider: LocalizedStringProvider()

        )
    }()

    override var controller: CreateSrvaEventController {
        get {
            _controller
        }
    }

    private let locationManager = LocationManager()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (controller.canMoveSrvaEventToCurrentUserLocation()) {
            locationManager.addListener(self)
            locationManager.start()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        locationManager.removeListener(self)
    }

    override func navigateToNextViewAfterSaving(srvaEvent: CommonSrvaEvent) {
        if let srvaEventId = srvaEvent.localId?.int64Value {
            let viewSrvaEventController = ViewSrvaEventViewController(srvaEventId: srvaEventId)
            navigationController?.replaceViewController(
                viewControllerToPop: self,
                childViewControllers: [viewSrvaEventController],
                animated: true
            )
        } else {
            // just pop the navigation controller as we're unable to display srva
            navigationController?.popViewController(animated: true)
        }
    }

    override func getSaveButtonTitle() -> String {
        "Save".localized()
    }

    override func getViewTitle() -> String {
        "Srva".localized()
    }

    func onLocationChanged(newLocation: CLLocation?) {
        guard let etrsLocation = newLocation?.coordinate.toETRSCoordinate(source: .manual) else {
            return
        }

        let locationChanged = controller.tryMoveSrvaEventToCurrentUserLocation(location: etrsLocation)
        if (!locationChanged) {
            locationManager.removeListener(self, stopIfLastListener: true)
        }
    }
}
