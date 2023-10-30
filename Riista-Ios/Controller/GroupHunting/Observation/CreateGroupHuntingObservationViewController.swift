import Foundation
import CoreLocation
import UIKit
import SnapKit
import RiistaCommon


protocol CreateGroupHuntingObservationViewControllerListener: AnyObject {
    func onObservationCreated(observationTarget: GroupHuntingObservationTarget)
}

class CreateGroupHuntingObservationViewController : ModifyGroupHuntingObservationViewController<CreateGroupObservationController>,
    LocationListener {

    private lazy var _controller: RiistaCommon.CreateGroupObservationController = {
        RiistaCommon.CreateGroupObservationController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            huntingGroupTarget: huntingGroupTarget,
            sourceHarvestTarget: sourceHarvestTarget,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: CreateGroupObservationController {
        get {
            _controller
        }
    }

    private weak var listener: CreateGroupHuntingObservationViewControllerListener?

    /**
     * A location manager for updating the observation location if needed.
     */
    private let locationManager = LocationManager()

    private let disposeBag = DisposeBag()

    // The harvest acting as a basis for this observation
    private let sourceHarvestTarget: RiistaCommon.GroupHuntingHarvestTarget?

    init(huntingGroupTarget: IdentifiesHuntingGroup,
         sourceHarvestTarget: GroupHuntingHarvestTarget?,
         listener: CreateGroupHuntingObservationViewControllerListener) {
        self.listener = listener
        self.sourceHarvestTarget = sourceHarvestTarget
        super.init(huntingGroupTarget: huntingGroupTarget)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        controller.observationLocationCanBeMovedAutomatically.bindAndNotify { [weak self] canBeMoved in
            Thread.onMainThread {
                guard let self = self, let canBeMoved = canBeMoved?.boolValue else {
                    return
                }

                if (canBeMoved) {
                    self.locationManager.addListener(self)
                    self.locationManager.start()
                } else {
                    self.locationManager.removeListener(self, stopIfLastListener: true)
                }
            }
        }.disposeBy(disposeBag: disposeBag)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        disposeBag.disposeAll()
        locationManager.removeListener(self)
    }

    override func onSaveClicked() {
        tableView.showLoading()
        saveButton.isEnabled = false

        controller.createObservation(
            completionHandler: handleOnMainThread { [weak self] result, error in
                self?.tableView.hideLoading()
                self?.saveButton.isEnabled = true
                self?.onCreateObservationCompleted(result: result, error: error)
            }
        )
    }

    private func onCreateObservationCompleted(result: GroupHuntingObservationOperationResponse?, error: Error?) {
        guard let listener = self.listener else {
            print("No listener, can't really do much more than pop this viewcontroller")
            navigationController?.popViewController(animated: true)
            return
        }

        if (error != nil) {
            let errorDialog = AlertDialogBuilder.createError(
                message: "GroupHuntingObservationSaveFailedGeneric".localized()
            )
            navigationController?.present(errorDialog, animated: true, completion: nil)
            return
        }

        if let result = result as? GroupHuntingObservationOperationResponse.Success {
            let observationTarget = GroupHuntingTargetKt.createTargetForObservation(huntingGroupTarget,
                                                                                    observationId: result.observation.id)
            listener.onObservationCreated(observationTarget: observationTarget)
        } else {
            let errorDialog = AlertDialogBuilder.createError(
                message: "GroupHuntingObservationSaveFailedGeneric".localized()
            )
            navigationController?.present(errorDialog, animated: true, completion: nil)
        }
    }

    override func getSaveButtonTitle() -> String {
        "Save".localized()
    }

    override func getViewTitle() -> String {
        "GroupHuntingNewObservation".localized()
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
