import Foundation
import MaterialComponents
import RiistaCommon
import SnapKit

fileprivate let CELL_TYPE = DataFieldCellType.customUserInterface

protocol CreateHuntingDayCellListener: AnyObject {
    func onCreateHuntingDayRequested()
}

class CreateHuntingDayCell : TypedDataFieldCell<ViewHuntingDayField, CustomUserInterfaceField<ViewHuntingDayField>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private weak var listener: CreateHuntingDayCellListener?

    override func createSubviews(for container: UIView) {
        container.backgroundColor = UIColor.applicationColor(Primary)

        let label = UILabel()
        label.font = UIFont.appFont(fontSize: AppConstants.Font.LabelMedium)
        label.textColor = .white
        label.text = "GroupHuntingSuggestedHuntingDay".localized()
        label.numberOfLines = 0
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview().inset(12)
        }

        let createDayButton = MaterialButton()
        createDayButton.applyTextTheme(withScheme: MDCContainerScheme().apply { containerScheme in
            containerScheme.colorScheme = AppTheme.shared.colorSchemeInverted()
            containerScheme.typographyScheme = AppTheme.shared.createTypographyCheme(buttonTextSize: AppConstants.Font.ButtonMedium)
        })
        createDayButton.setTitle("GroupHuntingAddHuntingDay".localized(), for: .normal)
        createDayButton.setImage(UIImage(named: "plus")?.withRenderingMode(.alwaysTemplate), for: .normal)
        createDayButton.setImageTintColor(.white, for: .normal)
        createDayButton.onClicked = { [weak self] in
            self?.listener?.onCreateHuntingDayRequested()
        }
        container.addSubview(createDayButton)
        createDayButton.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(12)
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
            make.top.equalTo(label.snp.bottom).offset(4)
        }
    }


    class Factory : DataFieldCellFactory<ViewHuntingDayField> {
        private weak var createHuntingDayCellListener: CreateHuntingDayCellListener?

        init(createHuntingDayCellListener: CreateHuntingDayCellListener) {
            self.createHuntingDayCellListener = createHuntingDayCellListener
            super.init(cellType: CELL_TYPE)
        }

        override func canCreateCell(for dataField: DataField<ViewHuntingDayField>) -> Bool {
            if let customField = dataField as? CustomUserInterfaceField<ViewHuntingDayField> {
                return customField.id_.type == .actionCreateHuntingDay
            }
            return false
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(CreateHuntingDayCell.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<ViewHuntingDayField>) -> DataFieldCell<ViewHuntingDayField> {
            if (dataField.id_.type != .actionCreateHuntingDay) {
                fatalError("Unsupported custom UI type observed! (\(dataField.id_)")
            }

            let cell = tableView.dequeueReusableCell(
                withIdentifier: CELL_TYPE.reuseIdentifier,
                for: indexPath
            ) as! CreateHuntingDayCell

            cell.listener = createHuntingDayCellListener
            return cell
        }
    }
}
