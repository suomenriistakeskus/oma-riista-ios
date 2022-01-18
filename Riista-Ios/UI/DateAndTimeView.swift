import Foundation
import MaterialComponents
import SnapKit

/**
 * A custom view displaying date and time.
 */
class DateAndTimeView: UIStackView {
    static let defaultSpacing: CGFloat = 4

    var dateAndTime: Date = Date() {
        didSet {
            dateValueLabel.text = dateAndTime.formatDateOnly()
            timeValueLabel.text = dateAndTime.formatTime()
        }
    }

    var isEnabled: Bool = false {
        didSet {
            isDateEnabled = isEnabled
            isTimeEnabled = isEnabled
        }
    }

    var isDateEnabled: Bool = false {
        didSet {
            dateButton.isEnabled = isDateEnabled

            let enabled = isDateEnabled
            dateValueLabel.updateColor(isEnabled: enabled)
            dateIconImageView.updateColor(isEnabled: enabled)
        }
    }
    var isTimeEnabled: Bool = false {
        didSet {
            timeButton.isEnabled = isTimeEnabled

            let enabled = isTimeEnabled
            timeValueLabel.updateColor(isEnabled: enabled)
            timeIconImageView.updateColor(isEnabled: enabled)
        }
    }


    private(set) lazy var dateValueLabel: UILabel = {
        createValueLabel(valueText: dateAndTime.formatDateOnly())
    }()

    private lazy var dateIconImageView: UIImageView = {
        createImageView(imageName: "calendar")
    }()

    private(set) lazy var dateButton: MaterialButton = {
        createValueButton(valueLabel: dateValueLabel, iconImageView: dateIconImageView)
    }()

    private(set) lazy var timeValueLabel: UILabel = {
        createValueLabel(valueText: dateAndTime.formatTime())
    }()

    private lazy var timeIconImageView: UIImageView = {
        createImageView(imageName: "clock")
    }()

    private(set) lazy var timeButton: MaterialButton = {
        createValueButton(valueLabel: timeValueLabel, iconImageView: timeIconImageView)
    }()


    init() {
        super.init(frame: CGRect.zero)
        setup()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        axis = .horizontal
        distribution = .fillEqually
        alignment = .center
        spacing = DateAndTimeView.defaultSpacing

        addArrangedSubview(dateButton)
        addArrangedSubview(timeButton)
    }


    private func createValueButton(valueLabel: UILabel, iconImageView: UIImageView) -> MaterialButton {
        let button = MaterialButton()
        let containerScheme = MDCContainerScheme().apply { scheme in
            scheme.colorScheme = AppTheme.shared.colorScheme()
        }

        button.applyTextTheme(withScheme: containerScheme)

        // don't use buttons titleLabel / imageView as those are constrained by
        // the button and we want to position those elements differently.
        // -> Instead use custom UIImageView for the icon and given valueLabel as text label
        button.addSubview(iconImageView)
        button.addSubview(valueLabel)

        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(DateAndTimeView.defaultSpacing)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(DateAndTimeView.defaultSpacing)
        }

        button.snp.makeConstraints { make in
            // set a slightly lower priority for height constraint as that solves initial load
            // constraint issue when DateAndTimeView is displayed in UITableView
            make.height.greaterThanOrEqualTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }

        return button
    }

    private func createValueLabel(valueText: String) -> UILabel {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: AppConstants.Font.LabelXXLarge, fontWeight: .light)
        label.textAlignment = .left
        label.text = valueText
        label.updateColor(isEnabled: isEnabled)

        return label
    }

    private func createImageView(imageName: String) -> UIImageView {
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        iconImageView.updateColor(isEnabled: isEnabled)
        return iconImageView
    }
}

fileprivate extension UIImageView {
    func updateColor(isEnabled: Bool) {
        if (isEnabled) {
            tintColor = UIColor.applicationColor(Primary)
        } else {
            tintColor = UIColor.applicationColor(GreyDark)
        }
    }
}

fileprivate extension UILabel {
    func updateColor(isEnabled: Bool) {
        if (isEnabled) {
            textColor = UIColor.applicationColor(Primary)
        } else {
            textColor = UIColor.applicationColor(GreyDark)
        }
    }
}
