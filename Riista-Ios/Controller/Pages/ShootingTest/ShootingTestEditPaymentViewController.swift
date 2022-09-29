import Foundation

class ShootingTestEditPaymentViewController: UIViewController, ShootingTestValueButtonDelegate, ValueSelectionDelegate {
    @IBOutlet weak var participantTitle: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hunterNumberLabel: UILabel!
    @IBOutlet weak var paymentsTitleLabel: UILabel!
    @IBOutlet weak var totalTitleLabel: UILabel!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var paidTitleLabel: UILabel!
    @IBOutlet weak var paidAmountValue: ShootingTestValueButton!
    @IBOutlet weak var remainingTitleLabel: UILabel!
    @IBOutlet weak var remainingAmountLabel: UILabel!
    @IBOutlet weak var finishedCheckbox: ShootingTestCheckbox!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!

    @IBAction func cancelPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func savePressed(_ sender: UIButton) {
        self.saveUpdatedPaymentState()
    }

    var participantId: Int?
    var participant: ShootingTestParticipantSummary?

    override func viewDidLoad() {
        super.viewDidLoad()

        Styles.styleButton(self.saveButton)
        Styles.styleNegativeButton(self.cancelButton)

        self.paidAmountValue.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.participantTitle.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestPaymentParticipantTitle").uppercased()
        self.paymentsTitleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestPaymentTitle").uppercased()
        self.totalTitleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestPaymentTotal")
        self.paidTitleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestPaymentPaid")
        self.remainingTitleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestPaymentRemaining")
        self.finishedCheckbox.setTitle(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestPaymentTestFinished"))

        self.cancelButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "Cancel"), for: .normal)
        self.saveButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "Save"), for: .normal)

        title = "ShootingTestPaymentEditTitle".localized()
        if (self.participant == nil) {
            self.refreshData()
        }
    }

    func refreshData() {
        ShootingTestManager.getParticipantSummary(participantId: self.participantId!) { (result:Any?, error:Error?) in
            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let item = try JSONDecoder().decode(ShootingTestParticipantSummary.self, from: json)

                    self.participant = item
                    self.refreshUi(item: self.participant!)
                }
                catch {
                    print("Failed to parse <ShootingTestParticipantSummary> item")
                }
            }
            else {
                print("getParticipantSummary failed: " + (error?.localizedDescription)!)
            }
        }
    }

    private func refreshUi(item: ShootingTestParticipantSummary) {
        self.nameLabel.text = String(format: "%@ %@", item.lastName!, item.firstName!)
        self.hunterNumberLabel.text = item.hunterNumber!

        self.totalAmountLabel.text = String(format: "%d €", item.totalDueAmount!)
        self.paidAmountValue.setTitle(text: String(format: "%d €", item.paidAmount!))
        self.remainingAmountLabel.text = String(format: "%d €", item.remainingAmount!)

        self.finishedCheckbox.setChecked(checked: item.completed!)

        self.saveButton.isEnabled = true
    }

    private func saveUpdatedPaymentState() {
        let valueText = self.paidAmountValue.getTitle()
        let words = valueText!.components(separatedBy: " ")
        let paidCount = Int(words[0])! / 20

        ShootingTestManager.updatePaymentStateForParticipant(participantId: self.participantId!,
                                                             rev: (self.participant?.rev)!,
                                                             paidAttempts: paidCount,
                                                             completed: self.finishedCheckbox.getChecked())
        { (result:Any?, error:Error?) in
            if (error == nil) {
                self.navigationController?.popViewController(animated: true)
            }
            else {
                print("updatePaymentStateForParticipant failed: " + (error?.localizedDescription)!)
            }
        }
    }

    // MARK: ShootingTestValueButtonDelegate

    func didPressButton(_ tag: Int) {
        let sb = UIStoryboard.init(name: "DetailsStoryboard", bundle: nil)
        let controller = sb.instantiateViewController(withIdentifier: "valueListController") as! ValueListViewController
        controller.delegate = self
        controller.fieldKey = "PAID_AMOUNT"
        controller.titlePrompt = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestPaymentPaid")

        var valueList:[String] = [String(format: "%d €", 0)]
        var i = 0

        let totalValue = Int((self.participant?.totalDueAmount)!)
        while (i < totalValue) {
            i += 20
            valueList.append(String(format: "%d €", i))
        }
        controller.values = valueList

        let segue = UIStoryboardSegue.init(identifier: "", source: self, destination: controller, performHandler: {
            self.navigationController?.pushViewController(controller, animated: true)
        })
        segue.perform()
    }

    // MARK: ValueSelectionDelegate
    func valueSelected(forKey key: String!, value: String!) {
        self.paidAmountValue.setTitle(text: value)

        let words = value.components(separatedBy: " ")
        let paidAmount = Int(words[0])!

        self.remainingAmountLabel.text = String((self.participant?.totalDueAmount)! - paidAmount)
    }
}
