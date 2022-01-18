import Foundation
import SnapKit

/**
 * A view for acting as a placeholder until proper view is implemented / loaded.
 */
class PlaceholderView: UIView {

    private(set) var label: UILabel!

    init(text: String = "") {
        super.init(frame: CGRect.zero)
        configurePlaceholder()
        label.text = text
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configurePlaceholder()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configurePlaceholder()
    }

    private func configurePlaceholder() {
        label = UILabel()
        label.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        label.adjustsFontSizeToFitWidth = false
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .black
        label.textAlignment = .center
        addSubview(label)

        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(1)
            /*make.center.equalToSuperview().labeled("label is centered")
            make.width.lessThanOrEqualToSuperview().labeled("label width limit")
            make.height.lessThanOrEqualToSuperview().labeled("label height limit")*/
        }
    }
}
