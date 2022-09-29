import Foundation
import RiistaCommon

@objc class CreateSrvaEventViewControllerHelper : NSObject {
    @objc class func createViewController() -> UIViewController {
        return CreateSrvaEventViewController()
    }
}

class CreateSrvaEventViewController :
    ModifySrvaEventViewController<CreateSrvaEventController>,
    LocationListener {

    private lazy var _controller: RiistaCommon.CreateSrvaEventController = {
        RiistaCommon.CreateSrvaEventController(
            metadataProvider: RiistaSDK.shared.metadataProvider,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: CreateSrvaEventController {
        get {
            _controller
        }
    }

    private let locationManager = LocationManager()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (controller.canMoveSrvaEventToCurrentUserLocation()) {
            locationManager.addListener(self)
            locationManager.start()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        locationManager.removeListener(self)
    }

    override func onSaveClicked() {
        guard let srvaEvent = controller.getValidatedSrvaEvent() else {
            return
        }

        tableView.showLoading()
        saveButton.isEnabled = false

        let srvaEntry = srvaEvent.toSrvaEntry(context: moContext)
        srvaEntry.sent = false
        let diaryImageSet = NSOrderedSet(array: newImages(srvaEvent) as [Any])
        srvaEntry.addDiaryImages(diaryImageSet)

        SrvaSaveOperations.sharedInstance().saveNewSrv(srvaEntry) { [weak self] response, error in
            NotificationCenter.default.post(Notification(name: .LogEntrySaved))
            NotificationCenter.default.post(Notification(name: .LogEntryTypeSelected,
                                                         object: NSNumber(value: RiistaEntryTypeSrva.rawValue)))
            self?.navigateToDiaryLog()
        }
    }

    override func getSaveButtonTitle() -> String {
        "Save".localized()
    }

    override func getViewTitle() -> String {
        "Srva".localized()
    }

    func onLocationChanged(newLocation: CLLocation?) {
        guard let etrsLocation = newLocation?.coordinate.toETRSCoordinate(source: .manual) else {
            return
        }

        let locationChanged = controller.tryMoveSrvaEventToCurrentUserLocation(location: etrsLocation)
        if (!locationChanged) {
            locationManager.removeListener(self, stopIfLastListener: true)
        }
    }

    private func navigateToDiaryLog() {
        navigationController?.popViewController(animated: true)
    }
}
