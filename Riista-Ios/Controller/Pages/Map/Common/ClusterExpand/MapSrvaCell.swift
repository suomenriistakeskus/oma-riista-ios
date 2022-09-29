import Foundation
import SnapKit
import RiistaCommon

fileprivate let ITEM_TYPE: MapClusteredItemViewModel.ItemType = .srva

protocol MapSrvaCellClickHandler: AnyObject {
    func onSrvaClicked(srvaId: ItemId)
}


class MapSrvaCell: MapDiaryEntryCell {
    static let reuseIdentifier = ITEM_TYPE.name

    override var itemType: MapClusteredItemViewModel.ItemType { .srva }

    override var diaryEntryIconImage: UIImage {
        UIImage(named: "srva")!
    }

    weak var clickHandler: MapSrvaCellClickHandler?
    private var boundViewModel: MapSrvaViewModel?

    func bind(srvaViewModel: MapSrvaViewModel) {
        bindValues(
            speciesCode: srvaViewModel.speciesCode,
            pointOfTime: srvaViewModel.pointOfTime,
            acceptStatus: srvaViewModel.acceptStatus,
            description: srvaViewModel.description
        )
        boundViewModel = srvaViewModel
    }

    override func onClicked() {
        guard let clickHandler = self.clickHandler else {
            print("No click handler, cannot handle srva click")
            return
        }
        guard let srvaId = boundViewModel?.id else {
            print("No srvaId/acceptStatus, cannot handle cell click")
            return
        }

        clickHandler.onSrvaClicked(srvaId: srvaId)
    }
}
