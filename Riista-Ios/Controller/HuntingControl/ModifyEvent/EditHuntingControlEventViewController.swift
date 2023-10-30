import Foundation
import CoreLocation
import UIKit
import SnapKit
import RiistaCommon


protocol EditHuntingControlEventViewControllerListener: AnyObject {
    func onHuntingControlEventUpdated(eventTarget: HuntingControlEventTarget)
}

class EditHuntingControlEventViewController :
    ModifyHuntingControlEventViewController<EditHuntingControlEventController> {

    private let huntingControlEventTarget: HuntingControlEventTarget
    private lazy var _controller: RiistaCommon.EditHuntingControlEventController = {
        RiistaCommon.EditHuntingControlEventController(
            huntingControlEventTarget: huntingControlEventTarget,
            stringProvider: LocalizedStringProvider(),
            huntingControlContext: RiistaSDK.shared.huntingControlContext,
            commonFileProvider: RiistaSDK.shared.commonFileProvider,
            userContext: RiistaSDK.shared.currentUserContext
        )
    }()

    override var controller: EditHuntingControlEventController {
        get {
            _controller
        }
    }

    private weak var listener: EditHuntingControlEventViewControllerListener?


    init(huntingControlEventTarget: HuntingControlEventTarget,
         listener: EditHuntingControlEventViewControllerListener) {
        self.huntingControlEventTarget = huntingControlEventTarget
        self.listener = listener

        super.init(huntingControlRhyTarget: HuntingControlRhyTarget(rhyId: huntingControlEventTarget.rhyId))
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func onSaveClicked() {
        tableView.showLoading()
        saveButton.isEnabled = false

        controller.saveHuntingControlEvent(
            updateToBackend: AppSync.shared.isAutomaticSyncEnabled(),
            completionHandler: handleOnMainThread { [weak self] result, error in
                self?.tableView.hideLoading()
                self?.saveButton.isEnabled = true
                self?.onHuntingControlEventUpdated(result: result, error: error)
            }
        )
    }

    private func onHuntingControlEventUpdated(result: HuntingControlEventOperationResponse?, error: Error?) {
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
            listener.onHuntingControlEventUpdated(eventTarget: eventTarget)
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
        "HuntingControlEditEvent".localized()
    }
}
