import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.labelInformation


/**
 * A cell for representing LabelFields with type of INFO.
 */
class InformationLabelFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, LabelField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private lazy var informationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.numberOfLines = 0
        return label
    }()

    override var containerView: UIView {
        informationLabel
    }

    // not really but these adjust text position nicely in respect to other fields
    override var internalTopPadding: CGFloat { return -4 }
    override var internalBottomPadding: CGFloat { return -4 }

    override func createSubviews(for container: UIView) {
        // nop, but needed since superview will crash otherwise
    }

    override func fieldWasBound(field: LabelField<FieldId>) {
        if (field.settings.allCaps) {
            informationLabel.text = field.text.uppercased()
        } else {
            informationLabel.text = field.text
        }

        if (field.settings.textAlignment == LabelFieldTextAlignment.left) {
            informationLabel.textAlignment = .left
        } else if (field.settings.textAlignment == LabelFieldTextAlignment.center) {
            informationLabel.textAlignment = .center
        } else if (field.settings.textAlignment == LabelFieldTextAlignment.justified) {
            informationLabel.textAlignment = .justified
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {

        init() {
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(InformationLabelFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! InformationLabelFieldCell<FieldId>

            return cell
        }
    }
}
