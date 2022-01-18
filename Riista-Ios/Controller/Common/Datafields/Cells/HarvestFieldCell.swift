import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.harvest

protocol HarvestFieldCellClickHandler: AnyObject {
    func onHarvestClicked(harvestId: Int64, acceptStatus: AcceptStatus)
}

class HarvestFieldCell<FieldId : DataFieldId>: DiaryEntryFieldCell<FieldId, HarvestField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    override var diaryEntryIconImage: UIImage {
        UIImage(named: "harvest")!
    }

    private weak var clickHandler: HarvestFieldCellClickHandler?

    override func fieldWasBound(field: HarvestField<FieldId>) {
        onValuesBound(
            speciesCode: field.speciesCode,
            amount: field.amount,
            pointOfTime: field.pointOfTime,
            acceptStatus: field.acceptStatus
        )
    }

    override func onClicked() {
        guard let clickHandler = self.clickHandler else {
            print("No click handler, cannot handle harvest click")
            return
        }
        guard let harvestId = boundField?.harvestId,
              let acceptStatus = boundField?.acceptStatus else {
            print("No harvestId/acceptStatus, cannot handle cell click")
            return
        }

        clickHandler.onHarvestClicked(harvestId: harvestId, acceptStatus: acceptStatus)
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        private weak var harvestCellClickHandler: HarvestFieldCellClickHandler?
        init(harvestCellClickHandler: HarvestFieldCellClickHandler?) {
            self.harvestCellClickHandler = harvestCellClickHandler
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(HarvestFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! HarvestFieldCell<FieldId>

            cell.clickHandler = harvestCellClickHandler

            return cell
        }
    }
}
