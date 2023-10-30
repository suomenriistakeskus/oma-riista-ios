import Foundation
import RiistaCommon

class ShootingTestCell: UITableViewCell {
    private static let stringProvider = LocalizedStringProvider()

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var rhyNameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    func setup(shootingTest: RiistaCommon.ShootingTest) {
        titleLabel.text = shootingTest.type.localized(stringProvider: Self.stringProvider)
        rhyNameLabel.text = shootingTest.rhyName
        durationLabel.text = String(
            format: "%@ - %@",
            shootingTest.begin.toFoundationDate().formatDateOnly(),
            shootingTest.end.toFoundationDate().formatDateOnly()
        )
    }

    func clearValues() {
        titleLabel.text = "-"
        rhyNameLabel.text = "-"
        durationLabel.text = "-"
    }
}
