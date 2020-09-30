import Foundation

class OccupationsCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var rhyNameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    func setup(item: Occupation, langCode: String) {
        let names = item.name as! Dictionary<String, String>
        titleLabel.text = names[langCode] != nil ? names[langCode] : names["fi"]

        let organisationName = item.organisation.name as! Dictionary<String, String>
        rhyNameLabel.text = organisationName[langCode] != nil ? organisationName[langCode] : organisationName["fi"]

        if (item.beginDate == nil && item.endDate == nil) {
            durationLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "DurationIndefinite")
        }
        else {
            durationLabel.text = String(format: "%@ - %@",
                                        item.beginDate != nil ? DatetimeUtil.dateToFormattedStringNoTime(date: item.beginDate) : "",
                                        item.endDate != nil ? DatetimeUtil.dateToFormattedStringNoTime(date: item.endDate) : "")
        }
    }
}
