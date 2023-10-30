import Foundation
import UIKit
import SnapKit
import RiistaCommon


protocol EditGroupObservationListener: AnyObject {
    func onObservationApproved()
    func onObservationUpdated()
}

class EditGroupHuntingObservationViewController : ModifyGroupHuntingObservationViewController<EditGroupObservationController> {

    private lazy var _controller: RiistaCommon.EditGroupObservationController = {
        RiistaCommon.EditGroupObservationController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            observationTarget: observationTarget,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: EditGroupObservationController {
        get {
            _controller
        }
    }

    enum Mode {
        case approve
        case edit
    }

    let mode: Mode
    private weak var listener: EditGroupObservationListener?
    private let observationTarget: GroupHuntingObservationTarget

    init(observationTarget: GroupHuntingObservationTarget,
         mode: Mode,
         listener: EditGroupObservationListener) {
        self.mode = mode
        self.listener = listener
        self.observationTarget = observationTarget

        super.init(huntingGroupTarget: observationTarget)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func onSaveClicked() {
        tableView.showLoading()
        saveButton.isEnabled = false

        // accept is same as save for observations
        controller.acceptObservation(
            completionHandler: handleOnMainThread { [weak self] result, error in
                guard let self = self else {
                    print("No self? Was viewcontroller dismissed while approving observation?")
                    return
                }

                self.tableView.hideLoading()
                self.saveButton.isEnabled = true
                self.onObservationSaveCompleted(result: result, error: error)
            }
        )
    }

    private func onObservationSaveCompleted(result: GroupHuntingObservationOperationResponse?, error: Error?) {
        guard let listener = self.listener else {
            print("No action listener, can't really do much more than pop this viewcontroller")
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

        if result is GroupHuntingObservationOperationResponse.Success {
            switch mode {
            case .approve:
                listener.onObservationApproved()
                break
            case .edit:
                listener.onObservationUpdated()
                break
            }
        } else {
            let errorDialog = AlertDialogBuilder.createError(
                message: "GroupHuntingObservationSaveFailedGeneric".localized()
            )
            navigationController?.present(errorDialog, animated: true, completion: nil)
        }
    }

    override func getSaveButtonTitle() -> String {
        switch mode {
        case .approve:  return "Approve".localized()
        case .edit:     return "Save".localized()
        }
    }

    override func getViewTitle() -> String {
        switch mode {
        case .approve:  return "ApproveObservation".localized()
        case .edit:     return "Edit".localized()
        }
    }
}
