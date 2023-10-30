import Foundation
import UIKit
import SnapKit
import RiistaCommon


class CreateGroupHuntingDayViewController:
    ModifyGroupHuntingDayViewController<CreateGroupHuntingDayController> {

    private let huntingGroupTarget: RiistaCommon.IdentifiesHuntingGroup

    private lazy var _controller: RiistaCommon.CreateGroupHuntingDayController = {
        RiistaCommon.CreateGroupHuntingDayController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            huntingGroupTarget: huntingGroupTarget,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: CreateGroupHuntingDayController {
        get {
            _controller
        }
    }

    init(huntingGroupTarget: RiistaCommon.IdentifiesHuntingGroup,
         preferredDate: RiistaCommon.LocalDate?,
         delegate: ModifyGroupHuntingDayViewControllerDelegate) {
        self.huntingGroupTarget = huntingGroupTarget
        super.init(delegate: delegate)

        controller.preferredDate = preferredDate
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func onSaveClicked() {
        tableView.showLoading()
        saveButton.isEnabled = false

        // accept is same as save for observations
        controller.saveHuntingDay(
            completionHandler: handleOnMainThread { [weak self] result, error in
                self?.tableView.hideLoading()
                self?.saveButton.isEnabled = true
                self?.onHuntingDaySaveCompleted(result: result, error: error)
            }
        )
    }

    private func onHuntingDaySaveCompleted(result: GroupHuntingDayUpdateResponse?, error: Error?) {
        guard let delegate = self.delegate else {
            print("No action listener, can't really do much more than pop this viewcontroller")
            navigationController?.popViewController(animated: true)
            return
        }

        if (error != nil) {
            let errorDialog = AlertDialogBuilder.createError(
                message: "GroupHuntingDaySaveFailedGeneric".localized()
            )
            navigationController?.present(errorDialog, animated: true, completion: nil)
            return
        }

        if result is GroupHuntingDayUpdateResponse.Updated {
            delegate.onHuntingDaySaved()
        } else {
            let errorDialog = AlertDialogBuilder.createError(
                message: "GroupHuntingDaySaveFailedGeneric".localized()
            )
            navigationController?.present(errorDialog, animated: true, completion: nil)
        }
    }
}

