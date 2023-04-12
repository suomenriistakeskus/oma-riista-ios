import Foundation
import RiistaCommon

@objcMembers class CreateHarvestViewControllerHelper : NSObject {
    class func createViewController() -> UIViewController {
        return CreateHarvestViewController(initialSpeciesCode: nil)
    }

    class func createViewController(species: RiistaSpecies) -> UIViewController {
        return CreateHarvestViewController(initialSpeciesCode: species.speciesId)
    }
}

class CreateHarvestViewController :
    ModifyHarvestViewController<CreateHarvestController>,
    LocationListener {

    private lazy var _controller: CreateHarvestController = {
        let controller = CreateHarvestController(
            harvestSeasons: RiistaSDK.shared.harvestSeasons,
            permitProvider: appPermitProvider,
            speciesResolver: SpeciesInformationResolver(),
            stringProvider: LocalizedStringProvider()
        )
        controller.modifyHarvestActionHandler = self
        controller.initialSpeciesCode = initialSpeciesCode?.toKotlinInt()

        return controller
    }()

    override var controller: CreateHarvestController {
        get {
            _controller
        }
    }

    /**
     * A location manager for updating the harvest location if needed.
     */
    private let locationManager = LocationManager()

    let initialSpeciesCode: Int?

    init(initialSpeciesCode: Int?) {
        self.initialSpeciesCode = initialSpeciesCode
        super.init()
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
        guard let harvest = controller.getValidatedHarvest() else {
            return
        }

        tableView.showLoading()
        saveButton.isEnabled = false

        let harvestEntry = harvest.toDiaryEntry(context: moContext)
        harvestEntry.sent = false
        harvestEntry.pendingOperation = NSNumber(value: DiaryEntryOperationInsert)

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

                NotificationCenter.default.post(Notification(name: .LogEntrySaved))
                NotificationCenter.default.post(Notification(name: .LogEntryTypeSelected,
                                                             object: NSNumber(value: RiistaEntryTypeHarvest.rawValue)))

                if let modifyListener: ModifyHarvestCompletionListener = self.navigationController?.findViewController() {
                    modifyListener.updateUserInterfaceAfterHarvestSaved()
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    override func getViewTitle() -> String {
        "Loggame".localized()
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
