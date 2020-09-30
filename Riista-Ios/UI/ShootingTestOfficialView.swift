import UIKit

protocol OfficialViewDelegate {
    func didPressButton(_ isAddAction: Bool, tag: Int)
}

class ShootingTestOfficialView: RiistaNibView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var button: UIButton!

    @IBAction func buttonPressed(_ sender: UIButton) {
        self.delegate?.didPressButton(!isSelected, tag:sender.tag)
    }

    var delegate: OfficialViewDelegate?
    var isSelected = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        self.contentView.frame.size.height = button.frame.height + 4
        self.frame.size = self.contentView.frame.size
    }
}
