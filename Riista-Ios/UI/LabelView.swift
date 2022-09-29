import Foundation
import SnapKit



/**
 * A view for labels.
 */
class LabelView: UIView {

    var text: String = "" {
        didSet {
            updateText()
        }
    }

    var required: Bool = false {
        didSet {
            updateText()
        }
    }

    private(set) lazy var label: UILabel = {
        UILabel().configure(for: .label, fontWeight: .semibold)
    }()

    override var forFirstBaselineLayout: UIView {
        get {
            label
        }
    }

    override var forLastBaselineLayout: UIView {
        get {
            label
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        configureLabel()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLabel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLabel()
    }

    private func configureLabel() {
        // label probably does not require user interaction..
        isUserInteractionEnabled = false
        // by default use zero layoutMargins but still constrain the actual label to layoutMarginGuide.
        // This allows users of this class to configure content insets.
        layoutMargins = UIEdgeInsets.zero

        addSubview(label)

        label.snp.makeConstraints { make in
            make.edges.equalTo(self.layoutMarginsGuide)
        }
    }

    private func updateText() {
        let labelText = NSMutableAttributedString(attributedString: text.toAttributedString(textAttributes))
        if (required) {
            labelText.append(" *".toAttributedString(requiredIndicatorAttributes))
        }

        label.attributedText = labelText
        label.sizeToFit()
    }
}


fileprivate let textAttributes = [
    NSAttributedString.Key.foregroundColor : UIColor.applicationColor(TextPrimary)!
]

fileprivate let requiredIndicatorAttributes = [
    NSAttributedString.Key.foregroundColor : UIColor.red
]
