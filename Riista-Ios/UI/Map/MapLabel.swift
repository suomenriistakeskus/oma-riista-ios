import Foundation

/**
 * A label having semi-transparent background in order to enhance label visibility on the map
 */
class MapLabel: LabelWithPadding {

    convenience init() {
        self.init(frame: CGRect.zero)
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
        configure(for: .label, textColor: .black)
        backgroundColor = .white.withAlphaComponent(0.8)
    }
}
