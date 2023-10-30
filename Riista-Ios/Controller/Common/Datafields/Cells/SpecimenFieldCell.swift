import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.specimen

typealias SpecimenLauncher<FieldId> = (_ fieldId: FieldId, _ specimenData: SpecimenFieldDataContainer, _ allowEdit: Bool) -> Void

class SpecimenFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, SpecimenField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var specimenLauncher: SpecimenLauncher<FieldId>? = nil

    private lazy var specimenButton: MaterialButton = {
        let button = MaterialButton()
        button.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        button.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "SpecimenDetailsTitle"), for: .normal)

        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }

        button.onClicked = { [weak self] in
            self?.handleClicked()
        }
        return button
    }()

    override var containerView: UIView {
        return specimenButton
    }

    override func createSubviews(for container: UIView) {
        // nop
    }

    private func handleClicked() {
        guard let field = boundField else {
            return
        }

        specimenLauncher?(field.id_, field.specimenData, !field.settings.readOnly)
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        var specimenLauncher: SpecimenLauncher<FieldId>? = nil

        init(specimenLauncher: SpecimenLauncher<FieldId>?) {
            self.specimenLauncher = specimenLauncher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(SpecimenFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! SpecimenFieldCell<FieldId>

            cell.specimenLauncher = specimenLauncher

            return cell
        }
    }
}
