import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.labelError


/**
 * A cell for representing LabelFields with type of INFO.
 */
class ErrorLabelFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, LabelField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private lazy var errorLabelBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xE34256).withAlphaComponent(0.13) // roughly the same than on android
        return view
    }()


    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(Destructive)
        label.numberOfLines = 0
        return label
    }()
    private var errorLabelInsetConstraint: Constraint?

    // not really but these adjust text position nicely in respect to other fields
    override var internalTopPadding: CGFloat { return -4 }
    override var internalBottomPadding: CGFloat { return -4 }

    override func createSubviews(for container: UIView) {
        // nop, but needed since superview will crash otherwise
        container.addSubview(errorLabelBackground)
        container.addSubview(errorLabel)

        errorLabelBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        errorLabel.snp.makeConstraints { make in
            errorLabelInsetConstraint = make.edges.equalTo(errorLabelBackground.snp.edges).inset(12).constraint
        }

    }

    override func fieldWasBound(field: LabelField<FieldId>) {
        if (field.settings.highlightBackground) {
            errorLabelBackground.isHidden = false
            errorLabelInsetConstraint?.update(inset: 12)
        } else {
            errorLabelBackground.isHidden = true
            errorLabelInsetConstraint?.update(inset: 0)
        }

        if (field.settings.allCaps) {
            errorLabel.text = field.text.uppercased()
        } else {
            errorLabel.text = field.text
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {

        init() {
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(ErrorLabelFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! ErrorLabelFieldCell<FieldId>

            return cell
        }
    }
}
