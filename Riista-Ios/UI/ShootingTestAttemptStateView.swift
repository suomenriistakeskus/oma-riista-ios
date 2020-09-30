import UIKit

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

    func refreshAttemptStateView(title: String, attempts: ShootingTestAttemptSummary?, intended:Bool?) {
        self.titleLabel.text = title

        if (attempts != nil) {
            setState(state: (attempts?.qualified!)! ? ShootingTestAttemptDetailed.ClassConstants.RESULT_QUALIFIED : ShootingTestAttemptDetailed.ClassConstants.RESULT_UNQUALIFIED,
                     attempts: (attempts?.attemptCount!)!)
        }
        else {
            setState(state: intended! ? "INTENDED" : "", attempts: 0)
        }
    }

    private func setState(state: String, attempts:Int) {
        if (attempts > 0) {
            self.attemptsLabel.text = String(format: "%d", attempts)
        }
        else {
            self.attemptsLabel.text = ""
        }

        self.view.backgroundColor = UIColor.clear

        switch state {
        case ShootingTestAttemptDetailed.ClassConstants.RESULT_QUALIFIED:
            self.view.backgroundColor = UIColor.applicationColor(ShootingTestQualifiedColor)
            self.imageView.image = UIImage(named: "ic_pass_white")
            break
        case ShootingTestAttemptDetailed.ClassConstants.RESULT_UNQUALIFIED:
            self.view.backgroundColor = UIColor.applicationColor(ShootingTestUnqualifiedColor)
            self.imageView.image = UIImage(named: "ic_fail_white")
            break
        case "INTENDED":
            self.view.backgroundColor = UIColor.applicationColor(ShootingTestIntendedColor)
            self.imageView.image = nil
            break
        default:
            self.view.backgroundColor = UIColor.applicationColor(ShootingTestNotIntendedColor).withAlphaComponent(0.3)
            self.imageView.image = nil
        }
    }
}
