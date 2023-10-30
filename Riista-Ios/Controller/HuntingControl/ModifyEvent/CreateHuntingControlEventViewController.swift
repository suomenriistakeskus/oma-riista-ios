import Foundation
import CoreLocation
import UIKit
import SnapKit
import RiistaCommon


protocol CreateHuntingControlEventViewControllerListener: AnyObject {
    func onHuntingControlEventCreated(eventTarget: HuntingControlEventTarget)
}

class CreateHuntingControlEventViewController :
    ModifyHuntingControlEventViewController<CreateHuntingControlEventController>,
    LocationListener {

    private lazy var _controller: RiistaCommon.CreateHuntingControlEventController = {
        RiistaCommon.CreateHuntingControlEventController(
            huntingControlContext: RiistaSDK.shared.huntingControlContext,
            huntingControlRhyTarget: huntingControlRhyTarget,
            stringProvider: LocalizedStringProvider(),
            commonFileProvider: RiistaSDK.shared.commonFileProvider,
            userContext: RiistaSDK.shared.currentUserContext
        )
    }()

    override var controller: CreateHuntingControlEventController {
        get {
            _controller
        }
    }

    private weak var listener: CreateHuntingControlEventViewControllerListener?

    /**
     * A location manager for updating the harvest location if needed.
     */
    private let locationManager = LocationManager()


    init(huntingControlRhyTarget: HuntingControlRhyTarget,
         listener: CreateHuntingControlEventViewControllerListener) {
        self.listener = listener
        super.init(huntingControlRhyTarget: huntingControlRhyTarget)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (controller.canMoveEventToCurrentUserLocation()) {
            locationManager.addListener(self)
            locationManager.start()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        locationManager.removeListener(self)
    }

    override func onSaveClicked() {
        tableView.showLoading()
        saveButton.isEnabled = false

        controller.saveHuntingControlEvent(
            updateToBackend: AppSync.shared.isAutomaticSyncEnabled(),
            completionHandler: handleOnMainThread { [weak self] result, error in
                self?.tableView.hideLoading()
                self?.saveButton.isEnabled = true
                self?.onHuntingControlEventCreated(result: result, error: error)
            }
        )
    }

    private func onHuntingControlEventCreated(result: HuntingControlEventOperationResponse?, error: Error?) {
        guard let listener = self.listener else {
            print("No listener, can't really do much more than pop this viewcontroller")
            navigationController?.popViewController(animated: true)
            return
        }

        if (error != nil) {
            let errorDialog = AlertDialogBuilder.createError(
                message: "GroupHuntingHarvestSaveFailedGeneric".localized()
            )
            navigationController?.present(errorDialog, animated: true, completion: nil)
            return
        }

        if let result = result as? HuntingControlEventOperationResponse.Success {
            let eventTarget = HuntingControlTargetKt.createTargetForEvent(huntingControlRhyTarget, eventId: result.event.localId)
            listener.onHuntingControlEventCreated(eventTarget: eventTarget)
        } else {
            let errorDialog = AlertDialogBuilder.createError(
                message: "GroupHuntingHarvestSaveFailedGeneric".localized()
            )
            navigationController?.present(errorDialog, animated: true, completion: nil)
        }
    }

    override func getSaveButtonTitle() -> String {
        "Save".localized()
    }

    override func getViewTitle() -> String {
        "HuntingControlNewEvent".localized()
    }

    func onLocationChanged(newLocation: CLLocation?) {
        guard let etrsLocation = newLocation?.coordinate.toETRSCoordinate(source: .manual) else {
            return
        }

        let locationChanged = controller.tryMoveEventToCurrentUserLocation(location: etrsLocation)
        if (!locationChanged) {
            locationManager.removeListener(self, stopIfLastListener: true)
        }
    }
}
