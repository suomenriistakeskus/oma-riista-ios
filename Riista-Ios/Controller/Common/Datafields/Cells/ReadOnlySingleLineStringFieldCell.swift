import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.readOnlyStringSingleLine

class ReadOnlySingleLineStringFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, StringField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private lazy var titleAndValueView: SingleLineTitleAndValue = {
        SingleLineTitleAndValue()
    }()

    override var containerView: UIView {
        titleAndValueView
    }

    override func createSubviews(for container: UIView) {
        // nop, but needed as otherwise super will fatalError us!
    }

    override func fieldWasBound(field: StringField<FieldId>) {
        if let label = field.settings.label {
            titleAndValueView.titleText = label.uppercased(with: RiistaSettings.locale())
        } else {
            titleAndValueView.titleText = ""
        }

        titleAndValueView.valueText = field.value// + demoStuff.randomElement()!

        // values changed -> ensure layout is checked i.e. can we display side-by-side
        // or does value need to be displayed below of title
        if let maxContentWidth = tableView?.layoutMarginsGuide.layoutFrame.width {
            titleAndValueView.updateLayout(maxContentWidth: maxContentWidth)
        } else {
            // try to obtain maxContentWidth again during layoutSubviews..
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        if (titleAndValueView.titleOrValueChanged) {
            let maxContentWidth = contentView.layoutMarginsGuide.layoutFrame.width
            titleAndValueView.updateLayout(maxContentWidth: maxContentWidth)

            // layout was just updated. UITableViewCell cannot update its height internally
            // once initial layout has been done so request tableview to update heights once
            // this layout pass has been completed.
            // - animations should only occur if cell has already been visible beforehand
            //   i.e. the content was updated
            setCellNeedsLayout(animateChanges: bindingState == .updated)
        }

        super.layoutSubviews()
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        init() {
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(ReadOnlySingleLineStringFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! ReadOnlySingleLineStringFieldCell<FieldId>

            return cell
        }
    }
}
