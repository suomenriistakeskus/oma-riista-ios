import Foundation
import MaterialComponents

/**
 * A custom button providing closure for click handling instead of typical addTarget(...)
 */
class MaterialButton: MDCButton {

    var onClicked: OnClicked? = nil

    init() {
        super.init(frame: CGRect.zero)
        setup()
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
        addTarget(self, action: #selector(onTouchUpInside), for: .touchUpInside)
    }

    @objc func onTouchUpInside() {
        self.onClicked?()
    }
}
