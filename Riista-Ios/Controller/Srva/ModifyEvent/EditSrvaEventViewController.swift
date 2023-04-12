import Foundation
import RiistaCommon

class EditSrvaEventViewController :
    ModifySrvaEventViewController<EditSrvaEventController> {

    var srvaEvent: EditableSrvaEvent

    private lazy var _controller: EditSrvaEventController = {
        EditSrvaEventController(
            metadataProvider: RiistaSDK.shared.metadataProvider,
            srvaContext: RiistaSDK.shared.srvaContext,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: EditSrvaEventController {
        get {
            _controller
        }
    }

    init(srvaEvent: EditableSrvaEvent) {
        self.srvaEvent = srvaEvent
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func onWillLoadViewModel(willRefresh: Bool) {
        controller.editableSrvaEvent = srvaEvent
    }

    override func navigateToNextViewAfterSaving(srvaEvent: CommonSrvaEvent) {
        navigationController?.popViewController(animated: true)
    }

    override func getViewTitle() -> String {
        "Srva".localized()
    }
}
