import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.labelIndicator

fileprivate let INDICATOR_COLORS: [LabelFieldLabelFieldSettingsIndicatorColor : UIColor] = [
    LabelFieldLabelFieldSettingsIndicatorColor.green : UIColor.applicationColor(ApplicationGreen)!,
    LabelFieldLabelFieldSettingsIndicatorColor.yellow : UIColor.applicationColor(ApplicationYellow)!,
    LabelFieldLabelFieldSettingsIndicatorColor.red : UIColor.applicationColor(ApplicationRed)!
]

/**
 * A cell for representing LabelFields with type of INDICATOR.
 */
class IndicatorLabelFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, LabelField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private(set) lazy var topLevelContainer: UIStackView = {
        let container = UIStackView()
        container.alignment = .center
        container.spacing = 8
        return container
    }()

    private lazy var indicatorCircle: UIView = {
        let circle = ViewWithRoundedCorners()
        circle.roundedCorners = .allCorners()
        circle.cornerRadius = 12

        circle.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        return circle
    }()

    private lazy var indicatorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.numberOfLines = 0
        return label
    }()

    override var containerView: UIView {
        topLevelContainer
    }

    // not really but these adjust text position nicely in respect to other fields
    override var internalTopPadding: CGFloat { return -4 }
    override var internalBottomPadding: CGFloat { return -4 }

    override func createSubviews(for container: UIView) {
        guard let container = container as? UIStackView else {
            fatalError("Expected UIStackView as container!")
        }

        container.addView(indicatorCircle)
        container.addView(indicatorLabel)
    }

    override func fieldWasBound(field: LabelField<FieldId>) {
        if (field.settings.allCaps) {
            indicatorLabel.text = field.text.uppercased()
        } else {
            indicatorLabel.text = field.text
        }

        if let indicatorColor = INDICATOR_COLORS[field.settings.indicatorColor] {
            indicatorCircle.backgroundColor = indicatorColor
            indicatorCircle.isHidden = false
        } else {
            indicatorCircle.isHidden = true
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {

        init() {
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(IndicatorLabelFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! IndicatorLabelFieldCell<FieldId>

            return cell
        }
    }
}
