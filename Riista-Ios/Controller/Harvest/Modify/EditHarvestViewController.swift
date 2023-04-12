import Foundation
import RiistaCommon

class EditHarvestViewController :
    ModifyHarvestViewController<EditHarvestController> {

    var harvest: CommonHarvest

    private lazy var _controller: EditHarvestController = {
        let controller = EditHarvestController(
            harvestSeasons: RiistaSDK.shared.harvestSeasons,
            permitProvider: appPermitProvider,
            speciesResolver: SpeciesInformationResolver(),
            stringProvider: LocalizedStringProvider()
        )
        controller.modifyHarvestActionHandler = self

        return controller
    }()

    override var controller: EditHarvestController {
        get {
            _controller
        }
    }

    init(harvest: CommonHarvest) {
        self.harvest = harvest
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func onWillLoadViewModel(willRefresh: Bool) {
        controller.editableHarvest = EditableHarvest(harvest: harvest)
    }

    override func onSaveClicked() {
        guard let harvest = controller.getValidatedHarvest() else {
            return
        }

        guard let localUri = harvest.localUrl,
              let uri = URL(string: localUri),
              let objectId = moContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                  print("Unable to retrieve objectID")
            return
        }

        guard let harvestEntry = RiistaGameDatabase.sharedInstance().diaryEntry(with: objectId, context: moContext) else {
            print("Failed to obtain existing harvest entry for saving (id: \(objectId))")
            return
        }

        tableView.showLoading()
        saveButton.isEnabled = false

        harvestEntry.updateWithCommonHarvest(harvest: harvest, context: moContext)
        harvestEntry.sent = false
        harvestEntry.pendingOperation = NSNumber(value: DiaryEntryOperationNone)

        saveAndSynchronizeEditedHarvest(harvest: harvestEntry) { [weak self] success in
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

                if let modifyListener: ModifyHarvestCompletionListener = self.navigationController?.findViewController() {
                    modifyListener.updateUserInterfaceAfterHarvestSaved()
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    override func getViewTitle() -> String {
        "Harvest".localized()
    }
}
