import Foundation
import RiistaCommon

class EditSrvaEventViewController :
    ModifySrvaEventViewController<EditSrvaEventController> {

    var srvaEvent: CommonSrvaEvent

    private lazy var _controller: EditSrvaEventController = {
        EditSrvaEventController(
            metadataProvider: RiistaSDK.shared.metadataProvider,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: EditSrvaEventController {
        get {
            _controller
        }
    }

    init(srvaEvent: CommonSrvaEvent) {
        self.srvaEvent = srvaEvent
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func onWillLoadViewModel(willRefresh: Bool) {
        controller.editableSrvaEvent = EditableSrvaEvent(srvaEvent: srvaEvent)
    }

    override func onSaveClicked() {
        guard let srvaEvent = controller.getValidatedSrvaEvent() else {
            return
        }

        guard let localUri = srvaEvent.localUrl,
              let uri = URL(string: localUri),
              let objectId = moContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
                  print("Unable to retrieve objectID")
            return
        }

        tableView.showLoading()
        saveButton.isEnabled = false

        guard let entry = RiistaGameDatabase.sharedInstance().srvaEntry(with: objectId, context: moContext) else {
            print("Failed to obtain SRVA entry from database with id \(objectId)")
            return
        }

        entry.srvaEventSpecVersion = RiistaCommon.Constants.shared.SRVA_SPEC_VERSION.toNSNumber()
        entry.sent = false

        entry.state = srvaEvent.state.rawBackendEnumValue
        entry.coordinates = srvaEvent.location.toGeoCoordinate(context: moContext, existingCoordinates: entry.coordinates)

        entry.pointOfTime = srvaEvent.pointOfTime.toFoundationDate()
        entry.year = srvaEvent.pointOfTime.year.toNSNumber()
        entry.month = srvaEvent.pointOfTime.monthNumber.toNSNumber()

        entry.gameSpeciesCode = srvaEvent.species.toGameSpeciesCode()
        entry.otherSpeciesDescription = srvaEvent.otherSpeciesDescription

        entry.specimens = srvaEvent.specimens.toSrvaSpecimens(context: moContext)
        entry.totalSpecimenAmount = NSNumber(value: srvaEvent.specimens.count)

        entry.eventName = srvaEvent.eventCategory.rawBackendEnumValue
        entry.eventType = srvaEvent.eventType.rawBackendEnumValue
        entry.otherTypeDescription = srvaEvent.otherEventTypeDescription
        entry.eventResult = srvaEvent.eventResult.rawBackendEnumValue
        entry.methods = srvaEvent.methods.toMethodString()

        entry.otherMethodDescription = srvaEvent.otherMethodDescription
        entry.personCount = srvaEvent.personCount.toNSNumber()
        entry.timeSpent = srvaEvent.hoursSpent.toNSNumber()
        entry.descriptionText = srvaEvent.description_

        entry.deportationOrderNumber = srvaEvent.deportationOrderNumber
        entry.eventTypeDetail = srvaEvent.eventTypeDetail.rawBackendEnumValue
        entry.otherEventTypeDetailDescription = srvaEvent.otherEventTypeDetailDescription
        entry.eventResultDetail = srvaEvent.eventResultDetail.rawBackendEnumValue

        SrvaSaveOperations.sharedInstance().saveEditSrva(
            entry,
            newImages: newImages(srvaEvent),
            moContext: moContext,
            present: self.presentedViewController
        ) { [weak self] in
            // Return to log, because if autosync is enabled then objectID of edited SrvaEntry will change and we can't show it anymore
            guard let self = self else { return }

            let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
            if (viewControllers.count > 2) {
                self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    override func getViewTitle() -> String {
        "Srva".localized()
    }
}
