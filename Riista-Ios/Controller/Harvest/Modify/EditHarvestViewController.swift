import Foundation
import RiistaCommon

class EditHarvestViewController :
    ModifyHarvestViewController<EditHarvestController> {

    var harvest: EditableHarvest

    private lazy var _controller: EditHarvestController = {
        let controller = EditHarvestController(
            harvestSeasons: RiistaSDK.shared.harvestSeasons,
            harvestContext: RiistaSDK.shared.harvestContext,
            harvestPermitProvider: appHarvestPermitProvider,
            selectableHuntingClubs: RiistaSDK.shared.huntingClubsSelectableForEntriesFactory.create(),
            languageProvider: CurrentLanguageProvider(),
            preferences: RiistaSDK.shared.preferences,
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

    init(harvest: EditableHarvest) {
        self.harvest = harvest
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func onWillLoadViewModel(willRefresh: Bool) {
        controller.editableHarvest = harvest
    }

    override func navigateToNextViewAfterSaving(harvest: CommonHarvest) {
        navigationController?.popViewController(animated: true)
    }

    override func getViewTitle() -> String {
        "Harvest".localized()
    }
}
