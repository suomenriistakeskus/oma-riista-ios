import Foundation

class ShootingTestCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var rhyNameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    func setup(item: ShootingTest) {
        titleLabel.text = ShootingTestUtil.localizedTypeText(value: item.type)
        rhyNameLabel.text = item.rhyName
        durationLabel.text = String(format: "%@ - %@",
                                    ShootingTestUtil.serverDateStringToDisplayDate(serverDate: item.begin),
                                    ShootingTestUtil.serverDateStringToDisplayDate(serverDate: item.end))
    }
}
