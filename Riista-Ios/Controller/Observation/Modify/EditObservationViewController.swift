import Foundation
import RiistaCommon

class EditObservationViewController :
    ModifyObservationViewController<EditObservationController> {

    var observation: CommonObservation

    private lazy var _controller: EditObservationController = {
        EditObservationController(
            userContext: RiistaSDK.shared.currentUserContext,
            metadataProvider: RiistaSDK.shared.metadataProvider,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: EditObservationController {
        get {
            _controller
        }
    }

    init(observation: CommonObservation) {
        self.observation = observation
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func onWillLoadViewModel(willRefresh: Bool) {
        controller.editableObservation = EditableObservation(observation: observation)
    }

    override func onSaveClicked() {
        guard let observation = controller.getValidatedObservation() else {
            return
        }

        guard let localUri = observation.localUrl,
              let uri = URL(string: localUri),
              let objectId = moContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                  print("Unable to retrieve objectID")
            return
        }

        guard let observationEntry = RiistaGameDatabase.sharedInstance().observationEntry(with: objectId, context: moContext) else {
            print("Failed to obtain existing observation entry for saving (id: \(objectId))")
            return
        }

        tableView.showLoading()
        saveButton.isEnabled = false

        observationEntry.updateWithCommonObservation(observation: observation, context: moContext)
        observationEntry.sent = false
        observationEntry.pendingOperation = NSNumber(value: DiaryEntryOperationNone)

        saveAndSynchronizeEditedObservation(observation: observationEntry) { [weak self] success in
            guard let self = self else {
                return
            }

            self.saveButton.isEnabled = true
            self.tableView.hideLoading { [weak self] in
                guard let self = self else {
                    return
                }

                if (!success) {
                    let errorDialog = AlertDialogBuilder.createError(message: "NetworkOperationFailed".localized())
                    self.present(errorDialog, animated: true)
                    return
                }

                if let modifyListener: ModifyObservationCompletionListener = self.navigationController?.findViewController() {
                    modifyListener.updateUserInterfaceAfterObservationSaved()
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    override func getViewTitle() -> String {
        "Observation".localized()
    }
}
