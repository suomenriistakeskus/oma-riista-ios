import UIKit

protocol ShootingTestValueButtonDelegate {
    func didPressButton(_ tag: Int)
}

class ShootingTestValueButton: RiistaNibView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var title: UILabel!

    @IBAction func buttonPressed(_ sender: UIButton) {
        self.delegate?.didPressButton(sender.tag)
    }

    var delegate: ShootingTestValueButtonDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setTitle(text: String?) {
        self.title.text = text
    }

    func getTitle() -> String? {
        return self.title.text
    }

    func setIsEnabled(enabled: Bool) {
        self.button.isEnabled = enabled
    }

    func getIsEnabled() -> Bool {
        return self.button.isEnabled
    }
}
