import Foundation


/**
 * A view that prefers displaying label and value on single line.
 */
class SingleLineValueView: UIView {
    enum Mode {
        // label will wrap to second, third line if both label and value don't
        // fit on the same line
        // - useful when value width only takes < 50% of the screen
        case multilineLabel
    }

    private let mode: Mode

    lazy var label: UILabel = {
        let label = UILabel()
        AppTheme.shared.setupLabelFont(label: label)
        label.textColor = UIColor.applicationColor(TextPrimary)

        if (mode == .multilineLabel) {
            label.numberOfLines = 0
            label.setContentHuggingPriority(.defaultLow, for: .vertical)
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }
        return label
    }()

    lazy var valueLabel: UILabel = {
        let valueLabel = UILabel()
        AppTheme.shared.setupLabelFont(label: valueLabel)
        valueLabel.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelMedium)
        valueLabel.textColor = UIColor.applicationColor(TextPrimary)
        valueLabel.textAlignment = .right

        if (mode == .multilineLabel) {
            valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            valueLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        }
        return valueLabel
    }()

    init(mode: Mode) {
        self.mode = mode
        super.init(frame: CGRect.zero)
        setup()
    }

    required init?(coder: NSCoder) {
        mode = .multilineLabel
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(label)
        addSubview(valueLabel)

        label.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(12)
            make.firstBaseline.equalTo(label.snp.firstBaseline)
            make.trailing.equalToSuperview()
        }

        self.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(label)
            make.height.greaterThanOrEqualTo(valueLabel)
        }
    }
}
