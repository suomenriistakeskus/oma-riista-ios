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
    private let iconView = UIImageView()

    override func createSubviews(for container: UIView) {
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIColor.applicationColor(Primary)

        container.addSubview(captionView)
        container.addSubview(iconView)
        captionView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
        }
        iconView.snp.makeConstraints { make in
            make.leading.equalTo(captionView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualToSuperview()
            make.centerY.equalTo(captionView.snp.centerY)
        }
    }

    override func fieldWasBound(field: LabelField<FieldId>) {
        if (field.settings.allCaps) {
            captionView.text = field.text.uppercased()
        } else {
            captionView.text = field.text
        }
        setIcon(field)
    }

    private func setIcon(_ field: LabelField<FieldId>) {
        if let icon = field.settings.captionIcon {
            switch (icon) {
            case .verified:
                iconView.image = UIImage(named: "outline_verified_black_24pt")
                break
            default:
                iconView.isHidden = true
                return
            }
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
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
