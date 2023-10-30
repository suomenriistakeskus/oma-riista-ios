import UIKit
import RiistaCommon

class ShootingTestAttemptStateView: RiistaNibView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var attemptsLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        self.view.layer.cornerRadius = 4
    }

    func refreshAttemptStateView(title: String, attempt: CommonShootingTestParticipantAttempt?, intended: Bool?) {
        self.titleLabel.text = title

        setState(
            qualified: attempt?.qualified,
            intended: intended,
            attempts: attempt?.attemptCount ?? 0
        )
    }

    private func setState(qualified: Bool?, intended: Bool?, attempts: Int32) {
        if (attempts > 0) {
            self.attemptsLabel.text = String(format: "%d", Int(attempts))
        }
        else {
            self.attemptsLabel.text = ""
        }

        if let qualified = qualified {
            if (qualified) {
                self.view.backgroundColor = UIColor.applicationColor(ShootingTestQualifiedColor)
                self.imageView.image = UIImage(named: "ic_pass_white")
            } else {
                self.view.backgroundColor = UIColor.applicationColor(ShootingTestUnqualifiedColor)
                self.imageView.image = UIImage(named: "ic_fail_white")
            }
        } else if (intended == true) {
            self.view.backgroundColor = UIColor.applicationColor(ShootingTestIntendedColor)
            self.imageView.image = nil
        } else {
            self.view.backgroundColor = UIColor.applicationColor(ShootingTestNotIntendedColor).withAlphaComponent(0.3)
            self.imageView.image = nil
        }
    }
}
