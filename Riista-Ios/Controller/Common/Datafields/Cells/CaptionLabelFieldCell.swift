import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.labelCaption


/**
 * A cell for representing LabelFields with type of CAPTION.
 */
class CaptionLabelFieldCell<FieldId : DataFieldId>:
    TypedDataFieldCell<FieldId, LabelField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private let captionView = CaptionView()

    override func createSubviews(for container: UIView) {
        container.addSubview(captionView)
        captionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func fieldWasBound(field: LabelField<FieldId>) {
        if (field.settings.allCaps) {
            captionView.text = field.text.uppercased()
        } else {
            captionView.text = field.text
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {

        init() {
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(CaptionLabelFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! CaptionLabelFieldCell<FieldId>

            return cell
        }
    }
}
