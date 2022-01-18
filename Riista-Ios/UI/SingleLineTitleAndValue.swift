import Foundation

/**
 * A custom container that flows the value label view to the next line if it doesn't fit side-by-side with the title label.
 */
class SingleLineTitleAndValue: UIView {
    private(set) var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: AppConstants.Font.LabelSmall, fontWeight: .semibold)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    private(set) var valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: AppConstants.Font.LabelMedium, fontWeight: .regular)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()

    var titleText: String? {
        get {
            titleLabel.text
        }
        set(value) {
            if (value != titleText) {
                titleOrValueChanged = true
            }
            titleLabel.text = value
        }
    }

    var valueText: String? {
        get {
            valueLabel.text
        }
        set(value) {
            if (value != valueText) {
                titleOrValueChanged = true
            }
            valueLabel.text = value
        }
    }

    private enum DisplayMode {
        case horizontal
        case vertical
    }
    private var displayMode: DisplayMode?

    private(set) var titleOrValueChanged: Bool = false

    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        // size/position will be determined by constraints
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(valueLabel)
    }

    /**
     * Updates the layout. This function should be called after titleText or valueText have been changed.
     */
    func updateLayout(maxContentWidth: CGFloat) {
        titleLabel.preferredMaxLayoutWidth = maxContentWidth
        valueLabel.preferredMaxLayoutWidth = maxContentWidth

        titleOrValueChanged = false

        let spacing: CGFloat = 8
        let titleWidth = titleText?.getPreferredSize(font: titleLabel.font).width ?? 0
        let valueWidth = valueText?.getPreferredSize(font: valueLabel.font).width ?? 0

        let contentWidth = titleWidth + spacing + valueWidth
        if (contentWidth >= maxContentWidth) {
            displayBelowEachOther()
        } else {
            displaySideBySide()
        }
    }

    private func displaySideBySide(){
        displayMode = .horizontal

        titleLabel.removeAllConstraints()
        valueLabel.removeAllConstraints()

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor),
            // title and value shouldn't overlap since we're displaying them side-by-side.
            // -> just constraint them to fit self
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.intrinsicContentSize.height).withPriority(priority: 999),
            valueLabel.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor),
            valueLabel.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor).withPriority(priority: 999),
            valueLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            valueLabel.heightAnchor.constraint(equalToConstant: valueLabel.intrinsicContentSize.height).withPriority(priority: 999),
            self.bottomAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor),
            self.bottomAnchor.constraint(greaterThanOrEqualTo: valueLabel.bottomAnchor)
        ])
    }

    private func displayBelowEachOther() {
        displayMode = .vertical

        titleLabel.removeAllConstraints()
        valueLabel.removeAllConstraints()

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: titleLabel.intrinsicContentSize.height).withPriority(priority: 999),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: valueLabel.intrinsicContentSize.height).withPriority(priority: 999),
            self.bottomAnchor.constraint(equalTo: valueLabel.bottomAnchor)
        ])
    }
}

fileprivate extension NSLayoutConstraint {
    func withPriority(priority: Float) -> NSLayoutConstraint {
        withPriority(priority: UILayoutPriority(priority))
    }

    func withPriority(priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
