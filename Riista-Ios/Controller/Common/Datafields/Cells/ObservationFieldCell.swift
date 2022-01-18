import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.observation

protocol ObservationFieldCellClickHandler: AnyObject {
    func onObservationClicked(observationId: Int64, acceptStatus: AcceptStatus)
}

class ObservationFieldCell<FieldId : DataFieldId>: DiaryEntryFieldCell<FieldId, ObservationField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    override var diaryEntryIconImage: UIImage {
        UIImage(named: "observation")!
    }

    private weak var clickHandler: ObservationFieldCellClickHandler?

    override func fieldWasBound(field: ObservationField<FieldId>) {
        onValuesBound(
            speciesCode: field.speciesCode,
            amount: field.amount,
            pointOfTime: field.pointOfTime,
            acceptStatus: field.acceptStatus
        )
    }

    override func onClicked() {
        guard let clickHandler = self.clickHandler else {
            print("No click handler, cannot handle observation click")
            return
        }
        guard let observationId = boundField?.observationId,
              let acceptStatus = boundField?.acceptStatus else {
            print("No observationId/acceptStatus, cannot handle cell click")
            return
        }

        clickHandler.onObservationClicked(observationId: observationId, acceptStatus: acceptStatus)
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        private weak var observationCellClickHandler: ObservationFieldCellClickHandler?
        init(observationCellClickHandler: ObservationFieldCellClickHandler?) {
            self.observationCellClickHandler = observationCellClickHandler
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(ObservationFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! ObservationFieldCell<FieldId>

            cell.clickHandler = observationCellClickHandler

            return cell
        }
    }
}
