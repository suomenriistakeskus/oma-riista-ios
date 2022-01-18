import Foundation
import MaterialComponents

class ChangeUsernameView: UIStackView {

    private lazy var titleLabel: UILabel = {
        UILabel().apply { label in
            label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelXLarge)
            label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ChangeUsernameTitle")
            label.textColor = .white
            label.numberOfLines = 0
        }
    }()

    private lazy var messageLabel: UILabel = {
        UILabel().apply { label in
            label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelSmall)
            label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ChangeUsernameMessage")
            label.textColor = .white
            label.numberOfLines = 0
        }
    }()

    lazy var startRegistrationButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        btn.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ChangeUsernameAction"), for: .normal)
        btn.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return btn
    }()

    lazy var cancelButton: MaterialButton = {
        let btn = MaterialButton()
        btn.setTitleFont(AppTheme.shared.fontForSize(size: AppConstants.Font.ButtonMedium), for: .normal)
        btn.setBorderColor(.white, for: .normal)
        btn.setBorderWidth(1.5, for: .normal)
        btn.setBackgroundColor(.clear)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "Cancel"), for: .normal)
        btn.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return btn
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
        axis = .vertical
        alignment = .fill
        spacing = 8
        isLayoutMarginsRelativeArrangement = true
        layoutMargins = AppConstants.UI.DefaultEdgeInsets

        addView(titleLabel)
        addView(messageLabel)

        addSpacer(size: 8, canExpand: true)

        addView(startRegistrationButton)
        addView(cancelButton)
    }
}
