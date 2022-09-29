import Foundation

@objcMembers class AnnouncementViewController: UIViewController
{
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var senderLabel: UILabel?
    @IBOutlet weak var messageView: UITextView?

    var item: Announcement?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshData()
    }

    func refreshData() {
        titleLabel?.text = item?.subject ?? ""
        if let pointOfTime = item?.pointOfTime {
            timeLabel?.text = DatetimeUtil.dateToFormattedStringNoTime(date: pointOfTime)
        }
        else {
            timeLabel?.text = ""
        }

        senderLabel?.text = item?.senderAsText()

        messageView?.text = item?.body
    }
}
