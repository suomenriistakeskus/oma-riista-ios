import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.button

typealias OnButtonClicked<FieldId> = (_ fieldId: FieldId) -> Void

class ButtonFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, ButtonField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var clickHandler: OnButtonClicked<FieldId>? = nil

    private lazy var button: MaterialButton = {
        let button = MaterialButton()
        button.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())

        button.onClicked = { [weak self] in
            self?.handleClicked()
        }
        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }
        return button
    }()

    override var containerView: UIView {
        return button
    }

    weak var navigationControllerProvider: ProvidesNavigationController?

    override func createSubviews(for container: UIView) {
        // nop
    }

    override func fieldWasBound(field: ButtonField<FieldId>) {
        button.setTitle(field.text, for: .normal)
    }

    private func handleClicked() {
        guard let field = boundField else {
            return
        }

        clickHandler?(field.id_)
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        var clickHandler: OnButtonClicked<FieldId>? = nil

        init(clickHandler: OnButtonClicked<FieldId>?) {
            self.clickHandler = clickHandler
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(ButtonFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! ButtonFieldCell<FieldId>

            cell.clickHandler = clickHandler

            return cell
        }
    }
}
