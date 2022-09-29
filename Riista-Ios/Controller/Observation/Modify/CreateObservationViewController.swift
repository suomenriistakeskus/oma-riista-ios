import Foundation
import RiistaCommon

@objcMembers class CreateObservationViewControllerHelper : NSObject {
    class func createViewController() -> UIViewController {
        return CreateObservationViewController(initialSpeciesCode: nil)
    }

    class func createViewController(species: RiistaSpecies) -> UIViewController {
        return CreateObservationViewController(initialSpeciesCode: species.speciesId)
    }
}

class CreateObservationViewController :
    ModifyObservationViewController<CreateObservationController>,
    LocationListener {

    private lazy var _controller: CreateObservationController = {
        let controller = CreateObservationController(
            userContext: RiistaSDK.shared.currentUserContext,
            metadataProvider: RiistaSDK.shared.metadataProvider,
            stringProvider: LocalizedStringProvider()
        )

        controller.initialSpeciesCode = initialSpeciesCode?.toKotlinInt()

        return controller
    }()

    override var controller: CreateObservationController {
        get {
            _controller
        }
    }

    /**
     * A location manager for updating the observation location if needed.
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

        if (controller.canMoveObservationToCurrentUserLocation()) {
            locationManager.addListener(self)
            locationManager.start()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        locationManager.removeListener(self)
    }

    override func onSaveClicked() {
        guard let observation = controller.getValidatedObservation() else {
            return
        }

        tableView.showLoading()
        saveButton.isEnabled = false

        let observationEntry = observation.toObservationEntry(context: moContext)
        observationEntry.sent = false
        observationEntry.pendingOperation = NSNumber(value: DiaryEntryOperationInsert)

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

                NotificationCenter.default.post(Notification(name: .LogEntrySaved))
                NotificationCenter.default.post(Notification(name: .LogEntryTypeSelected,
                                                             object: NSNumber(value: RiistaEntryTypeObservation.rawValue)))

                if let modifyListener: ModifyObservationCompletionListener = self.navigationController?.findViewController() {
                    modifyListener.updateUserInterfaceAfterObservationSaved()
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    override func getViewTitle() -> String {
        "LogObservation".localized()
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
