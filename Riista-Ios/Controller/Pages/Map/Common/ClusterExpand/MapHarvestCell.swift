import Foundation
import SnapKit
import RiistaCommon

fileprivate let ITEM_TYPE: MapClusteredItemViewModel.ItemType = .harvest

protocol MapHarvestCellClickHandler: AnyObject {
    func onHarvestClicked(harvestId: ItemId, acceptStatus: AcceptStatus)
}

class MapHarvestCell: MapDiaryEntryCell {
    static let reuseIdentifier = ITEM_TYPE.name

    override var itemType: MapClusteredItemViewModel.ItemType { .harvest }

    override var diaryEntryIconImage: UIImage {
        UIImage(named: "harvest")!
    }

    weak var clickHandler: MapHarvestCellClickHandler?
    private var boundViewModel: MapHarvestViewModel?


    func bind(harvestViewModel: MapHarvestViewModel) {
        bindValues(
            speciesCode: harvestViewModel.speciesCode,
            pointOfTime: harvestViewModel.pointOfTime,
            acceptStatus: harvestViewModel.acceptStatus,
            description: harvestViewModel.description
        )
        boundViewModel = harvestViewModel
    }

    override func onClicked() {
        guard let clickHandler = self.clickHandler else {
            print("No click handler, cannot handle harvest click")
            return
        }
        guard let harvestId = boundViewModel?.id,
              let acceptStatus = boundViewModel?.acceptStatus else {
            print("No harvestId/acceptStatus, cannot handle cell click")
            return
        }

        clickHandler.onHarvestClicked(harvestId: harvestId, acceptStatus: acceptStatus)
    }
}
