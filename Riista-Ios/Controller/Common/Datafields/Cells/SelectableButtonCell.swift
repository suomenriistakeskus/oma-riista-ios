import Foundation
import SnapKit
import RiistaCommon


class SelectableButtonCell<FieldId : DataFieldId, FieldType: DataField<FieldId>>: TypedDataFieldCell<FieldId, FieldType> {

    private(set) lazy var topLevelContainer: UIStackView = {
        // use a vertical stackview for containing caption + buttons
        // -> allows hiding caption if necessary
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 6
        container.alignment = .fill
        return container
    }()

    private(set) lazy var captionLabel: LabelView = {
        let labelView = LabelView()
        return labelView
    }()

    private(set) lazy var buttonContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 8
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        return stackView
    }()

    override var containerView: UIView {
        return topLevelContainer
    }

    override func createSubviews(for container: UIView) {
        guard let container = container as? UIStackView else {
            fatalError("Expected UIStackView as container!")
        }

        container.addArrangedSubview(captionLabel)
        container.addArrangedSubview(buttonContainer)

        buttonContainer.snp.makeConstraints { make in
            // set a slightly lower priority for height constraint as that solves initial load
            // constraint issue when DateAndTimeView is displayed in UITableView
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }
    }

    func addButton(text: String, iconName: String?) -> SelectableMaterialButton {
        let button = SelectableMaterialButton()
        button.label.text = text
        if let iconName = iconName {
            // always as template in order to support tinting
            button.iconImageView.image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
            button.iconImageView.isHidden = false
        } else {
            button.iconImageView.image = nil
            button.iconImageView.isHidden = true
        }

        buttonContainer.addView(button)
        return button
    }

    override func fieldWasBound(field: FieldType) {
        // nop
    }
}
