import Foundation
import MaterialComponents
import SnapKit

class MaterialCardButton: MDCCard {
    lazy var button: MaterialVerticalButton = {
        let button = MaterialVerticalButton()
        button.applyTextTheme(withScheme: AppTheme.shared.cardButtonSchemeBolded())
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center

        return button
    }()

    lazy var badge: BadgeView = {
        BadgeView()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(button)

        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(badge)
        badge.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(16)
        }
    }

    func setTitle(_ title: String) {
        button.setTitle(title, for: .normal)
    }

    func setImage(named: String) {
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(UIImage(named: named)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImageTintColor(UIColor.applicationColor(Primary), for: .normal)
        button.setImageTintColor(UIColor.applicationColor(GreyDark), for: .disabled)
    }

    func setEnabled(enabled: Bool) {
        button.isEnabled = enabled
    }

    func setClickTarget(_ target: Any?, action: Selector) {
        button.addTarget(target, action: action, for: .touchUpInside)
    }
}
