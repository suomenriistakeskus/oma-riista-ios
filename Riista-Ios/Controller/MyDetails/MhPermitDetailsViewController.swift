import Foundation

import MaterialComponents.MaterialDialogs

class MhPermitDetailsViewController: UIViewController {

    @IBOutlet weak var permitTitle: UILabel!
    @IBOutlet weak var permitAreaTitle: UILabel!
    @IBOutlet weak var permitAreaValue: UILabel!
    @IBOutlet weak var permitNameTitle: UILabel!
    @IBOutlet weak var permitNameValue: UILabel!
    @IBOutlet weak var permitTimeTitle: UILabel!
    @IBOutlet weak var permitTimeValue: UILabel!
    @IBOutlet weak var feedbackButton: MDCButton!

    var item: MhPermit?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        AppTheme.shared.setupPrimaryButtonTheme(button: feedbackButton)

        title = "MyDetailsMhPermitTitle".localized()
        refreshData()
    }

    func refreshData() {
        let language = RiistaSettings.language()

        permitAreaTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsMhPermitArea")
        permitNameTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsMhPermitName")
        permitTimeTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsMhPermitPeriod")

        permitTitle.text = MhPermit.getLocalizedPermitTypeAndIdentifier(permit: item, languageCode: language)
        permitAreaValue.text = MhPermit.getLocalizedAreaNumberAndName(permit: item, languageCode: language)
        permitNameValue.text = MhPermit.getLocalizedPermitName(permit: item, languageCode: language)
        permitTimeValue.text = MhPermit.getPeriod(permit: item)

        feedbackButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsMhPermitHarvestFeedback"), for: .normal)
        Styles.styleButton(feedbackButton)

        let feedbackUrl = item?.getHarvestFeedbackUrl(languageCode: language)
        feedbackButton.isHidden = (feedbackUrl == nil)
    }

    func navigateToFeedback() {
        let language = RiistaSettings.language()
        guard let url = URL(string: (item?.getHarvestFeedbackUrl(languageCode: language))!) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @IBAction func onFeedbackClick(_ sender: UIButton, forEvent event: UIEvent) {
        let alert = MDCAlertController(title: "AlertTitle".localized(),
                                       message: "MyDetailsMhFeedbackAlertMessage".localized())
        let cancelAction = MDCAlertAction(title: "CancelRemove".localized(), handler: { (alert: MDCAlertAction!) -> Void in
            // User canceled
        })
        let confirmAction = MDCAlertAction(title: "Ok".localized(), handler: { (alert: MDCAlertAction!) -> Void in
            self.navigateToFeedback()
        })

        alert.addAction(cancelAction)
        alert.addAction(confirmAction)

        present(alert, animated: true, completion: nil)
    }
}
