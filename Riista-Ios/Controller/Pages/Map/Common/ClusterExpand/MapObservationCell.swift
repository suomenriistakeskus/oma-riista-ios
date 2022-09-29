import Foundation
import SnapKit
import RiistaCommon

fileprivate let ITEM_TYPE: MapClusteredItemViewModel.ItemType = .observation

protocol MapObservationCellClickHandler: AnyObject {
    func onObservationClicked(observationId: ItemId, acceptStatus: AcceptStatus)
}


class MapObservationCell: MapDiaryEntryCell {
    static let reuseIdentifier = ITEM_TYPE.name

    override var itemType: MapClusteredItemViewModel.ItemType { .observation }

    override var diaryEntryIconImage: UIImage {
        UIImage(named: "observation")!
    }

    weak var clickHandler: MapObservationCellClickHandler?
    private var boundViewModel: MapObservationViewModel?

    func bind(observationViewModel: MapObservationViewModel) {
        bindValues(
            speciesCode: observationViewModel.speciesCode,
            pointOfTime: observationViewModel.pointOfTime,
            acceptStatus: observationViewModel.acceptStatus,
            description: observationViewModel.description
        )
        boundViewModel = observationViewModel
    }

    override func onClicked() {
        guard let clickHandler = self.clickHandler else {
            print("No click handler, cannot handle observation click")
            return
        }
        guard let observationId = boundViewModel?.id,
              let acceptStatus = boundViewModel?.acceptStatus else {
            print("No observationId/acceptStatus, cannot handle cell click")
            return
        }

        clickHandler.onObservationClicked(observationId: observationId, acceptStatus: acceptStatus)
    }
}
