import Foundation
import UIKit
import SnapKit
import RiistaCommon


protocol EditGroupHarvestListener: AnyObject {
    /** Harvest has been approved.
     *
     * @param `canCreateObservation` Should a dialog be presented asking whether to create an observation based on harvest?
     */
    func onHarvestApproved(canCreateObservation: Bool)
    func onHarvestUpdated()
}

class EditGroupHuntingHarvestViewController : ModifyGroupHuntingHarvestViewController<EditGroupHarvestController> {

    private lazy var _controller: RiistaCommon.EditGroupHarvestController = {
        RiistaCommon.EditGroupHarvestController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            harvestTarget: harvestTarget,
            speciesResolver: SpeciesInformationResolver(),
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: EditGroupHarvestController {
        get {
            _controller
        }
    }

    enum Mode {
        case approve
        case edit
    }

    let mode: Mode
    private weak var listener: EditGroupHarvestListener?
    private let harvestTarget: GroupHuntingHarvestTarget

    init(harvestTarget: GroupHuntingHarvestTarget, mode: Mode, listener: EditGroupHarvestListener) {
        self.mode = mode
        self.listener = listener
        self.harvestTarget = harvestTarget

        super.init(huntingGroupTarget: harvestTarget)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func onSaveClicked() {
        switch mode {
        case .approve:
            approveHarvest()
            break
        case .edit:
            saveHarvest()
            break
        }
    }

    private func approveHarvest() {
        tableView.showLoading()
        saveButton.isEnabled = false

        controller.acceptHarvest(
            completionHandler: handleOnMainThread { [weak self] result, error in
                guard let self = self else {
                    print("No self? Was viewcontroller dismissed while approving harvest?")
                    return
                }

                self.tableView.hideLoading()
                self.saveButton.isEnabled = true
                self.onApproveCompleted(result: result, error: error)
            }
        )
    }

    private func onApproveCompleted(result: GroupHuntingHarvestOperationResponse?, error: Error?) {
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

        if result is GroupHuntingHarvestOperationResponse.Success {
            listener.onHarvestApproved(canCreateObservation: controller.shouldCreateObservation())
        } else {
            let errorDialog = AlertDialogBuilder.createError(
                message: "GroupHuntingHarvestSaveFailedGeneric".localized()
            )
            navigationController?.present(errorDialog, animated: true, completion: nil)
        }
    }

    private func saveHarvest() {
        tableView.showLoading()
        saveButton.isEnabled = false

        controller.updateHarvest(
            completionHandler: handleOnMainThread { [weak self] result, error in
                guard let self = self else {
                    print("No self? Was viewcontroller dismissed while updating harvest?")
                    return
                }

                self.tableView.hideLoading()
                self.saveButton.isEnabled = true
                self.onHarvestUpdateCompleted(result: result, error: error)
            }
        )
    }

    private func onHarvestUpdateCompleted(result: GroupHuntingHarvestOperationResponse?, error: Error?) {
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

        if result is GroupHuntingHarvestOperationResponse.Success {
            listener.onHarvestUpdated()
        } else {
            let errorDialog = AlertDialogBuilder.createError(
                message: "GroupHuntingHarvestSaveFailedGeneric".localized()
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
        case .approve:  return "ApproveHarvest".localized()
        case .edit:     return "Edit".localized()
        }
    }
}
