import Foundation
import MaterialComponents.MaterialButtons
import RiistaCommon


class ShootingTestEditPaymentViewController: BaseViewController, SelectSingleStringViewControllerDelegate {
    private static let singleAttemptCost: Int = 20

    @IBOutlet weak var participantTitle: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hunterNumberLabel: UILabel!
    @IBOutlet weak var paymentsTitleLabel: UILabel!
    @IBOutlet weak var totalTitleLabel: UILabel!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var paidTitleLabel: UILabel!
    @IBOutlet weak var paidAmountValue: UILabel!
    @IBOutlet weak var changPaidAmountButton: MaterialButton!
    @IBOutlet weak var remainingTitleLabel: UILabel!
    @IBOutlet weak var remainingAmountLabel: UILabel!
    @IBOutlet weak var finishedCheckbox: ShootingTestCheckbox!
    @IBOutlet weak var cancelButton: MDCButton!
    @IBOutlet weak var saveButton: MDCButton!

    @IBAction func cancelPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func savePressed(_ sender: UIButton) {
        self.saveUpdatedPaymentState()
    }

    private lazy var logger = AppLogger(for: self, printTimeStamps: false)

    var shootingTestManager: ShootingTestManager?
    var participantId: Int64?
    private var participant: CommonShootingTestParticipant? {
        didSet {
            self.paidAmount = participant?.paidAmount.toDecimalNumber().int64Value ?? 0
        }
    }

    var paidAmount: Int64 = 0 {
        didSet {
            guard let participant = self.participant else {
                logger.w { "Cannot update paidAmountValue.text as there's no participant" }
                return
            }

            self.paidAmountValue.text = participant.formatAmount(amount: paidAmount)
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        AppTheme.shared.setupPrimaryButtonTheme(button: self.changPaidAmountButton)
        self.saveButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        self.cancelButton.applyOutlinedTheme(withScheme: AppTheme.shared.primaryButtonScheme())

        changPaidAmountButton.onClicked = {
            self.startChangePaidAmount()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.participantTitle.text = "ShootingTestPaymentParticipantTitle".localized().uppercased()
        self.paymentsTitleLabel.text = "ShootingTestPaymentTitle".localized().uppercased()
        self.totalTitleLabel.text = "ShootingTestPaymentTotal".localized()
        self.paidTitleLabel.text = "ShootingTestPaymentPaid".localized()
        self.remainingTitleLabel.text = "ShootingTestPaymentRemaining".localized()
        self.finishedCheckbox.setTitle(text: "ShootingTestPaymentTestFinished".localized())

        self.cancelButton.setTitle("Cancel".localized(), for: .normal)
        self.saveButton.setTitle("Save".localized(), for: .normal)

        title = "ShootingTestPaymentEditTitle".localized()
        if (self.participant == nil) {
            self.refreshData()
        }
    }

    func refreshData() {
        guard let shootingTestManager = self.shootingTestManager, let participantId = self.participantId else {
            logger.v { "No shooting test manager / participant id, cannot refresh" }
            return
        }

        shootingTestManager.getParticipantSummary(participantId: participantId) { [weak self] participantResult, error in
            guard let self = self else { return }

            if let participant = participantResult {
                self.participant = participant
                self.refreshUi(participant: participant)
            } else {
                self.logger.w {
                    "getParticipantSummary failed: \(error?.localizedDescription ?? String(describing: error))"
                }
            }
        }
    }

    private func refreshUi(participant: CommonShootingTestParticipant) {
        self.nameLabel.text = participant.formattedFullNameFirstLast
        self.hunterNumberLabel.text = participant.hunterNumber ?? ""

        self.totalAmountLabel.text = participant.formattedTotalDueAmount
        self.paidAmountValue.text = participant.formattedPaidAmount
        self.remainingAmountLabel.text = participant.formattedRemainingAmount

        self.finishedCheckbox.setChecked(checked: participant.completed)

        self.saveButton.isEnabled = true
    }

    private func saveUpdatedPaymentState() {
        guard let shootingTestManager = self.shootingTestManager,
              let participantId = self.participantId,
              let participantRev = self.participant?.rev else {
            return
        }

        let paidCount = round(
            Double(integerLiteral: self.paidAmount) / Double(Self.singleAttemptCost)
        ).toDecimalNumber().intValue

        shootingTestManager.updatePaymentStateForParticipant(
            participantId: participantId,
            participantRev: participantRev,
            paidAttempts: paidCount,
            completed: self.finishedCheckbox.getChecked()
        ) { [weak self] success, error in
            guard let self = self else { return }

            if (success) {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.logger.w {
                    "updatePaymentStateForParticipant failed: \(error?.localizedDescription ?? String(describing: error))"
                }
            }
        }
    }

    // MARK: Change paid amount

    func startChangePaidAmount() {
        guard let participant = self.participant else {
            logger.w { "No participant, cannot show possible payments" }
            return
        }

        let totalDueAmount: Int64 = participant.totalDueAmount.toDecimalNumber().int64Value
        var selectableValues: [StringWithId] = stride(from: 0, through: totalDueAmount, by: Self.singleAttemptCost)
            .map { amount in
                StringWithId(
                    string: participant.formatAmount(amount: amount),
                    id: amount
                )
            }

        // should not happen as long as totalDueAmount is divisible by `Self.singleAttemptCost` but let's make sure
        // the totalDueAmount is also selectable when some day it can be something else..
        if let lastAddedValue = selectableValues.last?.id, lastAddedValue < totalDueAmount {
            selectableValues.append(
                StringWithId(
                    string: participant.formatAmount(amount: totalDueAmount),
                    id: totalDueAmount
                )
            )
        }

        let viewController = SelectSingleStringViewController()
        viewController.title = "ShootingTestPaymentPaid".localized()
        viewController.delegate = self
        viewController.setValues(values: selectableValues)

        self.navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: SelectSingleStringViewController

    func onStringSelected(string: SelectSingleStringViewController.SelectableString) {
        // id is the paid amount!
        self.paidAmount = string.id
        self.remainingAmountLabel.text = self.participant?.formatRemainingAmount(newPaidAmount: string.id)
    }
}
