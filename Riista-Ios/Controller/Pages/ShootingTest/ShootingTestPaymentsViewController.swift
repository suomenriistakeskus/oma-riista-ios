import UIKit
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialDialogs
import RiistaCommon


protocol ParticipantPaymentCellDelegate {
    func didPressComplete(_ tag: Int)
    func didPressEdit(_ tag: Int)
}

class ParticipantPaymentsCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stateView: UIView!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var bearView: ShootingTestAttemptStateView!
    @IBOutlet weak var mooseView: ShootingTestAttemptStateView!
    @IBOutlet weak var deerView: ShootingTestAttemptStateView!
    @IBOutlet weak var bowView: ShootingTestAttemptStateView!
    @IBOutlet weak var totalTitleLabel: UILabel!
    @IBOutlet weak var paidTitleLabel: UILabel!
    @IBOutlet weak var remainingTitleLabel: UILabel!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var paidAmountLabel: UILabel!
    @IBOutlet weak var remainingAmountLabel: UILabel!
    @IBOutlet weak var doneButton: MDCButton!
    @IBOutlet weak var editButton: MDCButton!

    var cellDelegate: ParticipantPaymentCellDelegate?

    @IBAction func completePressed(_ sender: UIButton) {
        self.cellDelegate?.didPressComplete(self.tag)
    }

    @IBAction func editPressed(_ sender: UIButton) {
        self.cellDelegate?.didPressEdit(self.tag)
    }
}

class ShootingTestPaymentsViewController: BaseViewController, UITableViewDataSource, ParticipantPaymentCellDelegate {
    @IBOutlet weak var sumOfPaymentsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    private var participants = [CommonShootingTestParticipant]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "refresh_white"),
            style: .plain,
            target: self,
            action: #selector(onRefreshClicked)
        )

        self.tableView.dataSource = self
        self.tableView.tableHeaderView = nil
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = "ShootingTestViewTitle".localized()
        refreshData()
    }

    @objc private func onRefreshClicked() {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        refreshData()
    }

    func refreshData() {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        tabBarVc.fetchEvent() { [weak self] shootingTestEvent, _ in
            guard let self = self else { return }

            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.sumOfPaymentsLabel.text = String(format: "ShootingTestTotalPaidAmount".localized(),
                                                  shootingTestEvent?.formattedTotalPaidAmount ?? "")
        }
        tabBarVc.shootingTestManager.listParticipantsForEvent { participants, error in
            if let participants = participants {
                self.participants = participants.sorted(by: { lhs, rhs in
                    let lhsNoAttempts = lhs.attempts.isEmpty == true && rhs.attempts.isEmpty == false
                    let lhsNotCompleted = !lhs.completed && rhs.completed
                    let lhsRegisteredEarlier = (lhs.registrationTime ?? "") < (rhs.registrationTime ?? "")

                    return lhsNoAttempts || lhsNotCompleted || lhsRegisteredEarlier
                })
                self.tableView.reloadData()
            } else {
                print("listParticipantsForEvent failed: \(error?.localizedDescription ?? String(describing: error))")
            }
        }
    }

    // MARK - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return participants.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "paymentItemCell", for: indexPath) as? ParticipantPaymentsCell else {
            fatalError("The dequeued cell is not an instance of ParticipantPaymentsCell.")
        }

        cell.cellDelegate = self
        cell.tag = indexPath.row

        let participant = participants[indexPath.row]

        if let hunterNumber = participant.hunterNumber {
            cell.titleLabel.text = "\(participant.formattedFullNameLastFirst), \(hunterNumber)"
        } else {
            cell.titleLabel.text = participant.formattedFullNameLastFirst
        }
        cell.stateView.isHidden = participant.completed
        cell.stateView.layer.cornerRadius = 3
        cell.stateView.clipsToBounds = true
        cell.stateView.backgroundColor = UIColor.applicationColor(Destructive)
        cell.stateLabel.text = "ShootingTestStateOngoing".localized()

        cell.totalTitleLabel.text = "ShootingTestPaymentTotal".localized()
        cell.paidTitleLabel.text = "ShootingTestPaymentPaid".localized()
        cell.remainingTitleLabel.text = "ShootingTestPaymentRemaining".localized()
        cell.totalAmountLabel.text = participant.formattedTotalDueAmount
        cell.paidAmountLabel.text = participant.formattedPaidAmount
        cell.remainingAmountLabel.text = participant.formattedRemainingAmount

        cell.bearView.refreshAttemptStateView(
            title: "ShootingTestTypeBearShort".localized(),
            attempt: participant.attemptSummaryFor(type: .bear),
            intended: false
        )
        cell.mooseView.refreshAttemptStateView(
            title: "ShootingTestTypeMooseShort".localized(),
            attempt: participant.attemptSummaryFor(type: .moose),
            intended: false
        )
        cell.deerView.refreshAttemptStateView(
            title: "ShootingTestTypeRoeDeerShort".localized(),
            attempt: participant.attemptSummaryFor(type: .roeDeer),
            intended: false
        )
        cell.bowView.refreshAttemptStateView(
            title: "ShootingTestTypeBowShort".localized(),
            attempt: participant.attemptSummaryFor(type: .bow),
            intended: false
        )

        cell.stateView.isHidden = participant.completed
        cell.doneButton.isEnabled = !participant.completed

        cell.doneButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        cell.doneButton.setImage(checkMarkImageTemplate, for: .normal)
        if (participant.completed) {
            cell.doneButton.setImageTintColor(UIColor.applicationColor(GreyDark), for: .disabled)
        } else {
            cell.doneButton.setImageTintColor(.white, for: .normal)
        }

        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        cell.editButton.isEnabled = tabBarVc.shootingTestEvent?.ongoing ?? false
        cell.editButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())

        return cell
    }

    // MARK - ParticipantPaymentCellDelegate

    func didPressComplete(_ tag: Int) {
        guard let participant = participants.getOrNil(index: tag) else {
            print("no participant for index \(tag), not completing")
            return
        }

        let alert = MDCAlertController(
            title: nil,
            message: String(format: "ShootingTestPaymentCompleteConfirm".localized(),
                            participant.lastName ?? "",
                            participant.firstName ?? "",
                            participant.hunterNumber ?? "")
        )
        alert.addAction(MDCAlertAction(title: "OK".localized()) { _ in
            self.completeAllPayments(participant: participant)
        })
        alert.addAction(MDCAlertAction(title: "No".localized(), handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func completeAllPayments(participant: CommonShootingTestParticipant) {
        guard let tabBarVc = self.tabBarController as? ShootingTestTabBarViewController else {
            print("no tab bar controller (i.e. no shooting test manager), not completing payments")
            return
        }

        tabBarVc.shootingTestManager.completeAllPayments(
            participantId: participant.id,
            participantRev: participant.rev
        ) { [weak self] success, error in
            guard let self = self else { return }

            if (success) {
                self.refreshData()
            } else {
                print("completeAllPayments failed: \(error?.localizedDescription ?? String(describing: error))")
            }
        }
    }

    func didPressEdit(_ tag: Int) {
        guard let shootingTestManagaer = (self.tabBarController as? ShootingTestTabBarViewController)?.shootingTestManager,
              let participant = participants.getOrNil(index: tag) else {
            print("no shooting test manager / participant, cannot edit payments")
            return
        }

        let vc = self.storyboard?.instantiateViewController(withIdentifier: "editPaymentViewController") as! ShootingTestEditPaymentViewController
        vc.participantId = participant.id
        vc.shootingTestManager = shootingTestManagaer
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

fileprivate let checkMarkImageTemplate = UIImage(named: "ic_pass_white.png")?.withRenderingMode(.alwaysTemplate)
