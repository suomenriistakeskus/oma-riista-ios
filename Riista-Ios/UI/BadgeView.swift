import Foundation
import SnapKit


class BadgeView: UIView {
    lazy var badgeLabel: UILabel = {
        let label = UILabel()
        label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelMedium, bolded: true)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()

    var text: String? {
        didSet {
            updateBadge()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        // adding cornerRadius to UILabels doesn't seem as easy as it should be
        // since there is no edge insets support. It seems that UILabel would need
        // to be subclassed. Instead let this class provide the background color
        // and rounder corners
        backgroundColor = UIColor.applicationColor(Destructive)
        layer.masksToBounds = true
        layer.cornerRadius = bounds.height

        addSubview(badgeLabel)

        updateBadge()
    }

    override func updateConstraints() {
        // refresh constraints so that we can access correct badgeLabel height
        badgeLabel.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(badgeLabel.bounds.height / 3)
        }

        super.updateConstraints()
    }

    private func updateBadge() {
        if let text = text {
            badgeLabel.text = text
            badgeLabel.sizeToFit()

            layer.cornerRadius = badgeLabel.bounds.height / 2

            setNeedsUpdateConstraints()

            fadeIn(duration: 0.3)
        } else {
            fadeOut(duration: 0.1)
        }
    }
}
