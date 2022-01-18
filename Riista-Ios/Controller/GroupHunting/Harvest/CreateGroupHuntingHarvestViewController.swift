import Foundation
import CoreLocation
import UIKit
import SnapKit
import RiistaCommon


protocol CreateGroupHuntingHarvestViewControllerListener: AnyObject {
    func onHarvestCreated(harvestTarget: GroupHuntingHarvestTarget, canCreateObservation: Bool)
}

class CreateGroupHuntingHarvestViewController :
    ModifyGroupHuntingHarvestViewController<CreateGroupHarvestController>,
    LocationListener {

    private lazy var _controller: RiistaCommon.CreateGroupHarvestController = {
        RiistaCommon.CreateGroupHarvestController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            huntingGroupTarget: huntingGroupTarget,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: CreateGroupHarvestController {
        get {
            _controller
        }
    }

    private weak var listener: CreateGroupHuntingHarvestViewControllerListener?

    /**
     * A location manager for updating the harvest location if needed.
     */
    private let locationManager = LocationManager()


    init(huntingGroupTarget: HuntingGroupTarget,
         listener: CreateGroupHuntingHarvestViewControllerListener) {
        self.listener = listener
        super.init(huntingGroupTarget: huntingGroupTarget)
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

    override func onSaveClicked() {
        tableView.showLoading()
        saveButton.isEnabled = false

        controller.createHarvest { [weak self] result, error in
            self?.tableView.hideLoading()
            self?.saveButton.isEnabled = true
            self?.onCreateHarvestCompleted(result: result, error: error)
        }
    }

    private func onCreateHarvestCompleted(result: GroupHuntingHarvestOperationResponse?, error: Error?) {
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

        if let result = result as? GroupHuntingHarvestOperationResponse.Success {
            let harvestTarget = GroupHuntingTargetKt.createTargetForHarvest(huntingGroupTarget,
                                                                            harvestId: result.harvest.id)
            listener.onHarvestCreated(
                harvestTarget: harvestTarget,
                canCreateObservation: controller.shouldCreateObservation()
            )
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
        "GroupHuntingNewHarvest".localized()
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
