import Foundation
import SnapKit

typealias OnToggled = (Bool) -> Void

class ToggleView: LabelAndControl {

    lazy var toggle: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = UIColor.applicationColor(Primary)
        toggle.addTarget(self, action: #selector(onToggleClicked), for: .valueChanged)
        return toggle
    }()

    var isToggledOn: Bool {
        get {
            toggle.isOn
        }
        set(value) {
            toggle.isOn = value
        }
    }

    init(labelText: String, labelAlignment: LabelAndControl.LabelAlignment = .leading, minHeight: CGFloat = 40.0) {
        super.init(frame: CGRect.zero, labelText: labelText, minHeight: minHeight)
        self.labelAlignment = labelAlignment
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /**
     * A callback to be called when toggle status changes.
     */
    var onToggled: OnToggled?

    func bind(isToggledOn: Bool, onToggled: @escaping OnToggled) {
        self.isToggledOn = isToggledOn
        self.onToggled = onToggled
    }

    override func getControlView() -> UIView {
        toggle
    }

    @objc func onToggleClicked() {
        onToggled?(isToggledOn)
    }
}
