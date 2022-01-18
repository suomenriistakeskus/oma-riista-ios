import Foundation
import MaterialComponents
import SnapKit

class LabelWithIconButton: UIView {
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelMedium)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping

        // resist horizontal compression bit more than spacing after icon. Also resist
        // growing bit less than other views
        // -> takes the space available but does not resist multilining
        label.setContentCompressionResistancePriority(UILayoutPriority(500), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(500), for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        return label
    }()

    lazy var trailingIconButton: MDCButton = {
        let button = MDCButton()
        button.applyTextTheme(withScheme: AppTheme.shared.buttonContainerScheme());
        return button
    }()

    init() {
        super.init(frame: CGRect.zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let spacingAfterTrailingIcon = UIView().apply { spacing in
            spacing.backgroundColor = .clear
            spacing.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            spacing.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }

        addSubview(label)
        addSubview(trailingIconButton)
        addSubview(spacingAfterTrailingIcon)

        label.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        trailingIconButton.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(12)
            make.trailing.equalTo(spacingAfterTrailingIcon.snp.leading)
            make.centerY.equalToSuperview()
        }

        spacingAfterTrailingIcon.snp.makeConstraints { make in
            make.centerY.trailing.equalToSuperview()
        }

        self.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(label)
            make.height.greaterThanOrEqualTo(trailingIconButton)
        }
    }
}
