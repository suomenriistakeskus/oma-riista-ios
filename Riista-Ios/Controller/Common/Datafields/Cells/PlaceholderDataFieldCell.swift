import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.placeholder

class PlaceholderDataFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, DataField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private lazy var placeholder: PlaceholderView = {
        PlaceholderView()
    }()

    override func createSubviews(for container: UIView) {
        container.addSubview(placeholder)
        placeholder.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func fieldWasBound(field: DataField<FieldId>) {
        print("Field \(field.id_) is unknown!")
        let type = DataFieldType(field)
        placeholder.label.text = "<\(type): \(field.id_)>"
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        init() {
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(PlaceholderDataFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! PlaceholderDataFieldCell<FieldId>

            return cell
        }
    }
}
