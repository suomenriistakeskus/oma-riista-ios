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
            dateButton.dateAndTime = dateAndTime
            timeButton.dateAndTime = dateAndTime
        }
    }

    var isEnabled: Bool = false {
        didSet {
            isDateEnabled = isEnabled
            isTimeEnabled = isEnabled
        }
    }

    var isDateEnabled: Bool {
        get {
            dateButton.isEnabled
        }
        set(enabled) {
            dateButton.isEnabled = enabled
        }
    }
    var isTimeEnabled: Bool {
        get {
            timeButton.isEnabled
        }
        set(enabled) {
            timeButton.isEnabled = enabled
        }
    }

    private(set) lazy var dateButton: DateOrTimeButton = {
        DateOrTimeButton(mode: .date)
    }()

    private(set) lazy var timeButton: DateOrTimeButton = {
        DateOrTimeButton(mode: .time)
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
}
