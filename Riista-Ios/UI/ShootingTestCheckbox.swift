import UIKit
import M13Checkbox

protocol ShootingTestCheckboxDelegate {
    func isCheckedChanged(_ checked: Bool)
}

class ShootingTestCheckbox: RiistaNibView, UIGestureRecognizerDelegate {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var checkbox: M13Checkbox!
    @IBOutlet weak var title: UILabel!

    var delegate: ShootingTestCheckboxDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    func commonInit() {
        self.checkbox.strokeColor = UIColor.applicationColor(ShootingTestQualifiedColor)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.delegate = self
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tap)
    }

    func setChecked(checked: Bool) {
        self.checkbox.checkState = checked ? M13CheckboxState.checked : M13CheckboxState.unchecked
        delegate?.isCheckedChanged(self.checkbox.checkState == M13CheckboxState.checked)
    }

    func getChecked() -> Bool {
        return self.checkbox.checkState == M13CheckboxState.checked ? true : false
    }

    func setTitle(text: String) {
        self.title.text = text
    }

    func getTitle() -> String {
        return self.title.text!
    }

    @objc func handleTap(sender: UITapGestureRecognizer? = nil) {
        self.checkbox.toggleCheckState()
        delegate?.isCheckedChanged(self.checkbox.checkState == M13CheckboxState.checked)
    }
}
