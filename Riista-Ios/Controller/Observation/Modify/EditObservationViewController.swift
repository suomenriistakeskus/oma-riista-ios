import Foundation
import RiistaCommon

class EditObservationViewController :
    ModifyObservationViewController<EditObservationController> {

    var observation: EditableObservation

    private lazy var _controller: EditObservationController = {
        EditObservationController(
            userContext: RiistaSDK.shared.currentUserContext,
            observationContext: RiistaSDK.shared.observationContext,
            metadataProvider: RiistaSDK.shared.metadataProvider,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: EditObservationController {
        get {
            _controller
        }
    }

    init(observation: EditableObservation) {
        self.observation = observation
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func onWillLoadViewModel(willRefresh: Bool) {
        controller.editableObservation = observation
    }

    override func navigateToNextViewAfterSaving(observation: CommonObservation) {
        navigationController?.popViewController(animated: true)
    }

    override func getViewTitle() -> String {
        "Observation".localized()
    }
}
