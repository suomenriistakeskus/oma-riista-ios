import Foundation
import MaterialComponents
import SnapKit

class SelectedMapAreaView: UIView {

    var areaType: AppConstants.AreaType?

    var title: String? {
        get {
            titleLabel.text
        }
        set(value) {
            titleLabel.text = value
            if (value != nil) {
                titleLabel.isHidden = false
            } else {
                titleLabel.isHidden = true
            }
        }
    }

    var name: String? {
        get {
            nameLabel.text
        }
        set(value) {
            nameLabel.text = value
            if (value != nil) {
                nameLabel.isHidden = false
            } else {
                nameLabel.isHidden = true
            }
        }
    }

    var areaId: String? {
        didSet {
            updateAreaIdLabel()
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelMedium)
        label.textColor = UIColor.applicationColor(GreyMedium)
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelMedium)
        label.textColor = UIColor.applicationColor(TextPrimary)
        return label
    }()

    private lazy var areaIdLabel: LabelWithIconButton = {
        let label = LabelWithIconButton()
        label.trailingIconButton.apply { button in
            button.setImage(UIImage(named: "copy_white_24pt"), for: .normal)
            button.setImageTintColor(UIColor.applicationColor(Primary), for: .normal)

            button.addTarget(self, action: #selector(onCopyAreaIdToPasteboard), for: .touchUpInside)
        }
        return label
    }()

    private(set) lazy var removeButton: MDCButton = {
        let button = MDCButton()
        button.setImage(UIImage(named: "cross"), for: .normal)
        button.applyTextTheme(withScheme: AppTheme.shared.buttonContainerScheme())
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc func onCopyAreaIdToPasteboard() {
        guard let areaId = self.areaId else {
            return
        }

        UIPasteboard.general.string = areaId
    }

    private func setup() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading

        addSubview(stackView)
        addSubview(removeButton)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(areaIdLabel)

        stackView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.trailing.equalTo(removeButton.snp.leading)
        }

        removeButton.snp.makeConstraints { make in
            make.height.width.equalTo(AppConstants.UI.ButtonHeightSmall)
            make.trailing.centerY.equalToSuperview()
        }

        self.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(stackView).offset(12).priority(750)
            make.height.greaterThanOrEqualTo(removeButton).offset(12).priority(750)
        }

        // finally a separator attached to the bottom
        // - these are shown and hidden and having attached separator makes showing/hiding separator easier
        let separator = UIView()
        separator.backgroundColor = UIColor.applicationColor(GreyLight)
        addSubview(separator)
        separator.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.bottom.leading.trailing.equalToSuperview()
        }
    }

    private func updateAreaIdLabel() {
        if let areaId = areaId {
            areaIdLabel.label.text = String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapAreaCodeFormat"), areaId)
            areaIdLabel.isHidden = false
        } else {
            areaIdLabel.isHidden = true
        }
    }
}
