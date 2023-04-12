import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.labelLink


/**
 * A cell for representing LabelFields with type of LINK.
 */
class LinkLabelFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, LabelField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private weak var actionEventDispatcher: ActionEventDispatcher?

    private lazy var backgroundButton: MaterialButton = {
        let button = MaterialButton()
        AppTheme.shared.setupTextButtonTheme(button: button)

        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(AppConstants.UI.TextButtonMinHeight).priority(999)
        }
        button.onClicked = { [weak self] in
            self?.dispatchClick()
        }
        return button
    }()

    private lazy var linkLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label, fontWeight: .medium)
        label.textColor = UIColor.applicationColor(Primary)
        label.numberOfLines = 0
        return label
    }()

//    override var containerView: UIView {
//        backgroundButton
//    }

    // not really but these adjust text position nicely in respect to other fields
    override var internalTopPadding: CGFloat { return -4 }
    override var internalBottomPadding: CGFloat { return -4 }

    override func createSubviews(for container: UIView) {
        container.addSubview(backgroundButton)
        backgroundButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        backgroundButton.addSubview(linkLabel)
        linkLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }

    override func fieldWasBound(field: LabelField<FieldId>) {
        if (field.settings.allCaps) {
            updateText(text: field.text.uppercased())
        } else {
            updateText(text: field.text)
        }
    }

    private func updateText(text: String) {
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttribute(
            NSAttributedString.Key.kern,
            value: 1.2, // bit more spacing between letters
            range: NSRange(location: 0, length: text.count - 1)
        )
        linkLabel.attributedText = attributedText
    }

    private func dispatchClick() {
        guard let fieldId = boundField?.id_, let eventDispatcher = actionEventDispatcher else {
            return
        }

        eventDispatcher.dispatchEvent(fieldId: fieldId)
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        private weak var actionEventDispatcher: ActionEventDispatcher?

        init(actionEventDispatcher: ActionEventDispatcher?) {
            self.actionEventDispatcher = actionEventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(LinkLabelFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! LinkLabelFieldCell<FieldId>

            cell.actionEventDispatcher = actionEventDispatcher

            return cell
        }
    }
}
