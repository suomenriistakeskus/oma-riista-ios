import Foundation
import SnapKit



/**
 * A view for captions.
 */
class CaptionView: UIView {

    var text: String = "" {
        didSet {
            updateText()
        }
    }

    private lazy var label: UILabel = {
        UILabel().configure(for: .label, fontWeight: .semibold)
    }()


    init(text: String = "") {
        super.init(frame: CGRect.zero)
        self.text = text
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
        addSubview(label)

        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        updateText()
    }

    private func updateText() {
        label.text = text
        label.sizeToFit()
    }
}
