import Foundation
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialDialogs
import RiistaCommon


protocol ParticipantAttemptCellDelegate {
    func didPressEdit(_ tag: Int)
    func didPressDelete(_ tag: Int)
}

class UserAttemptItemCell: UITableViewCell {
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var resultTitleLabel: UILabel!
    @IBOutlet weak var resultValueLabel: UILabel!
    @IBOutlet weak var hitsTitleLabel: UILabel!
    @IBOutlet weak var hitsValueLabel: UILabel!
    @IBOutlet weak var editButton: MDCButton!
    @IBOutlet weak var deleteButton: MDCButton!

    var cellDelegate: ParticipantAttemptCellDelegate?

    @IBAction func editPressed(_ sender: UIButton) {
        self.cellDelegate?.didPressEdit(self.tag)
    }

    @IBAction func deletePressed(_ sender: UIButton) {
        self.cellDelegate?.didPressDelete(self.tag)
    }
}

class ShootingTestUserAttemptsViewController: BaseViewController, UITableViewDataSource, ParticipantAttemptCellDelegate {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hunterNumberLabel: UILabel!
    @IBOutlet weak var dateOfBirthLabel:UILabel!
    @IBOutlet weak var addButton: MDCButton!
    @IBOutlet weak var tableView: UITableView!

    @IBAction func addPressed(_ sender: UIButton) {
        if (!self.isLocked) {
            guard let participantId = self.participant?.id, let participantRev = self.participant?.rev else {
                return
            }

            let vc = self.storyboard?.instantiateViewController(withIdentifier: "editAttemptViewController") as! ShootingTestEditAttemptViewController
            vc.participantId = participantId
            vc.participantRev = participantRev
            vc.shootingTestManager = self.shootingTestManager
            self.setEditTypeLimitsTo(vc: vc, editType: nil)

            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    var shootingTestManager: ShootingTestManager?
    var participantId: Int64? = nil
    var isLocked = false
    var participant: CommonShootingTestParticipantDetailed?
    var attempts = [CommonShootingTestAttempt]()

    private let stringProvider = LocalizedStringProvider()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.tableHeaderView = nil;
        self.tableView.tableFooterView = UIView();
        self.tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.addButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        self.addButton.isUppercaseTitle = false
        self.addButton.setTitle("ShootingTestAttemptListAdd".localized(), for: .normal)

        title = "ShootingTestAttemptListViewTitle".localized()
        self.refreshData()
    }

    func refreshUi(user: CommonShootingTestParticipantDetailed!) {
        self.nameLabel.text = user.formattedFullNameLastFirst
        self.hunterNumberLabel.text = user.hunterNumber
        self.dateOfBirthLabel.text = user.dateOfBirth?.toFoundationDate().formatDateOnly() ?? ""

        self.addButton.isEnabled = !self.isLocked
    }

    func refreshData() {
        guard let shootingTestManager = shootingTestManager,
                let participantId = participantId else {
            print("No shooting test manager / participant id, cannot fetch data")
            return
        }

        shootingTestManager.getParticipantDetailed(
            participantId: participantId
        ) { (participant: CommonShootingTestParticipantDetailed?, error: Error?) in
            if let participant = participant {
                self.participant = participant
                self.refreshUi(user: self.participant)

                self.attempts = participant.attempts
                self.tableView.reloadData()
            } else {
                print("getParticipantDetailed failed: \(error?.localizedDescription ?? String(describing: error))")
            }
        }
    }

    private func setEditTypeLimitsTo(vc: ShootingTestEditAttemptViewController, editType: ShootingTestType?) {
        var bearCount = 0
        var mooseCount = 0
        var roeDeerCount = 0
        var bowCount = 0

        attempts.filter { attempt in
            attempt.result.value != .rebated
        }.forEach { attempt in
            if (attempt.type.value == .bear) {
                bearCount += 1
            } else if (attempt.type.value == .moose) {
                mooseCount += 1
            } else if (attempt.type.value == .roeDeer) {
                roeDeerCount += 1
            } else if (attempt.type.value == .bow) {
                bowCount += 1
            }
        }

        vc.enableBear = bearCount < 5 || (bearCount == 5 && editType == .bear)
        vc.enableMoose = mooseCount < 5 || (mooseCount == 5 && editType == .moose)
        vc.enableRoeDeer = roeDeerCount < 5 || (roeDeerCount == 5 && editType == .roeDeer)
        vc.enableBow = bowCount < 5 || (bowCount == 5 && editType == .bow)
    }

    // MARK - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attempts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "attemptItemCell", for: indexPath) as? UserAttemptItemCell else {
            fatalError("The dequeued cell is not an instance of UserAttemptItemCell.")
        }

        cell.cellDelegate = self
        cell.tag = indexPath.row

        let item = attempts[indexPath.row]

        cell.typeLabel.text = item.type.localized(stringProvider: stringProvider)
        cell.resultTitleLabel.text = "ShootingTestAttemptListResultTitle".localized()
        cell.resultValueLabel.text = item.result.localized(stringProvider: stringProvider)
        cell.hitsTitleLabel.text = "ShootingTestAttemptListHitsTitle".localized()
        cell.hitsValueLabel.text = String(item.hits)

        cell.editButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        cell.deleteButton.applyContainedTheme(withScheme: AppTheme.shared.destructiveButtonScheme())

        cell.editButton.isEnabled = !self.isLocked
        cell.deleteButton.isEnabled = !self.isLocked

        return cell
    }

    // MARK - ParticipantAttemptCellDelegate

    func didPressEdit(_ tag: Int) {
        guard let participantId = self.participant?.id, let participantRev = self.participant?.rev else {
            return
        }

        let attempt = attempts[tag]

        let vc = self.storyboard?.instantiateViewController(withIdentifier: "editAttemptViewController") as! ShootingTestEditAttemptViewController
        vc.participantId = participantId
        vc.participantRev = participantRev
        vc.attemptId = attempt.id
        vc.shootingTestManager = self.shootingTestManager
        self.setEditTypeLimitsTo(vc: vc, editType: attempt.type.value)

        self.navigationController?.pushViewController(vc, animated: true)
    }

    func didPressDelete(_ tag: Int) {
        guard let shootingTestManager = self.shootingTestManager,
              let attempt = attempts.getOrNil(index: tag) else {
            print("no shooting test manager or attempt for index \(tag)")
            return
        }

        let alert = MDCAlertController(
            title: nil,
            message: "ShootingTestAttemptDeleteConfirm".localized()
        )
        alert.addAction(MDCAlertAction(title: "OK".localized(), handler: { action in
            shootingTestManager.deleteAttempt(attemptId: attempt.id) { [weak self] success, error in
                guard let self = self else { return }

                if (success) {
                    self.refreshData()
                } else {
                    print("deleteAttempt failed: \(error?.localizedDescription ?? String(describing: error))")
                }
            }
        }))
        alert.addAction(MDCAlertAction(title: "No".localized(), handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
