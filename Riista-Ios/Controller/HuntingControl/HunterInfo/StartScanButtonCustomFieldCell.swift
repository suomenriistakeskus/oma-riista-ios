import Foundation
import MaterialComponents
import RiistaCommon
import SnapKit

fileprivate let CELL_TYPE = DataFieldCellType.customUserInterface

protocol StartScanCellListener: AnyObject {
    func onStartScanRequested()
}

class StartScanButtonCell : TypedDataFieldCell<HunterInfoField, CustomUserInterfaceField<HunterInfoField>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private weak var listener: StartScanCellListener?

    private lazy var button: MaterialCardButton = {
        let button = MaterialCardButton()
        button.setTitle("ShootingTestRegisterReadQr".localized())
        button.setImage(named: "outline_qr_code_2_black_24pt")
        button.button.iconSize = CGSize(width: 40, height: 40)
        button.button.imageView?.contentMode = .scaleAspectFit
        button.setClickTarget(self, action: #selector(onClicked))

        button.button.applyTextTheme(withScheme: AppTheme.shared.cardButtonSchemeBolded().apply { containerScheme in
            containerScheme.colorScheme = colorScheme()
        })

        button.snp.makeConstraints { make in
            make.height.equalTo(button.snp.width).multipliedBy(0.33).priority(999)
        }
        return button
    }()

    private func colorScheme() -> MDCSemanticColorScheme {
        let colorScheme = MDCSemanticColorScheme(defaults: .material201907)
        colorScheme.backgroundColor = UIColor.applicationColor(ViewBackground)
        colorScheme.onPrimaryColor = UIColor.applicationColor(TextPrimary)
        colorScheme.primaryColor = UIColor.applicationColor(TextPrimary)
        colorScheme.primaryColorVariant = UIColor.applicationColor(PrimaryDark)
        return colorScheme
    }

    override func createSubviews(for container: UIView) {
        // no-op
    }

    override var containerView: UIView {
        return button
    }

    @objc func onClicked() {
        listener?.onStartScanRequested()
    }

    class Factory : DataFieldCellFactory<HunterInfoField> {
        private weak var startScanCellListener: StartScanCellListener?

        init(startScanCellListener: StartScanCellListener) {
            self.startScanCellListener = startScanCellListener
            super.init(cellType: CELL_TYPE)
        }

        override func canCreateCell(for dataField: DataField<HunterInfoField>) -> Bool {
            if let customField = dataField as? CustomUserInterfaceField<HunterInfoField> {
                return customField.id_.type == .scanQrCode
            }
            return false
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(StartScanButtonCell.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<HunterInfoField>) -> DataFieldCell<HunterInfoField> {
            if (dataField.id_.type != .scanQrCode) {
                fatalError("Unsupported custom UI type observed! (\(dataField.id_)")
            }

            let cell = tableView.dequeueReusableCell(
                withIdentifier: CELL_TYPE.reuseIdentifier,
                for: indexPath
            ) as! StartScanButtonCell

            cell.listener = startScanCellListener
            return cell
        }
    }
}

