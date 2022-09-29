import Foundation
import MaterialComponents
import SnapKit

/**
 * A custom button for  displaying either date or time value.
 */
class DateOrTimeButton: MaterialButton {
    static let defaultSpacing: CGFloat = 4

    enum Mode {
        case date, time
    }

    let mode: Mode

    var dateAndTime: Date = Date() {
        didSet {
            valueLabel.text = valueText
        }
    }

    var valueText: String {
        switch mode {
        case .date: return dateAndTime.formatDateOnly()
        case .time: return dateAndTime.formatTime()
        }
    }

    override var isEnabled: Bool {
        didSet {
            let enabled = isEnabled
            valueLabel.updateColor(isEnabled: enabled)
            iconImageView.updateColor(isEnabled: enabled)
        }
    }


    private(set) lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: .xxLarge, fontWeight: .light)
        label.textAlignment = .left
        label.text = valueText
        label.updateColor(isEnabled: isEnabled)

        return label
    }()

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: mode.imageName)?.withRenderingMode(.alwaysTemplate)
        iconImageView.updateColor(isEnabled: isEnabled)
        return iconImageView
    }()

    init(mode: Mode) {
        self.mode = mode
        super.init(frame: CGRect.zero)
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setup() {
        let containerScheme = MDCContainerScheme().apply { scheme in
            scheme.colorScheme = AppTheme.shared.colorScheme()
        }

        applyTextTheme(withScheme: containerScheme)

        // don't use buttons titleLabel / imageView as those are constrained by
        // the button and we want to position those elements differently.
        // -> Instead use custom UIImageView for the icon and given valueLabel as text label
        addSubview(iconImageView)
        addSubview(valueLabel)

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

        self.snp.makeConstraints { make in
            // set a slightly lower priority for height constraint as that solves initial load
            // constraint issue when DateAndTimeView is displayed in UITableView
            make.height.greaterThanOrEqualTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }
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


fileprivate extension DateOrTimeButton.Mode {
    var imageName: String {
        switch self {
        case .date:     return "calendar"
        case .time:     return "clock"
        }
    }
}
