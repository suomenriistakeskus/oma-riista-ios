import Foundation
import MaterialComponents.MaterialDialogs

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
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!

    var cellDelegate: ParticipantAttemptCellDelegate?

    @IBAction func editPressed(_ sender: UIButton) {
        self.cellDelegate?.didPressEdit(self.tag)
    }

    @IBAction func deletePressed(_ sender: UIButton) {
        self.cellDelegate?.didPressDelete(self.tag)
    }
}

class ShootingTestUserAttemptsViewController: UIViewController, UITableViewDataSource, ParticipantAttemptCellDelegate {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hunterNumberLabel: UILabel!
    @IBOutlet weak var dateOfBirthLabel:UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    @IBAction func addPressed(_ sender: UIButton) {
        if (!self.isLocked) {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "editAttemptViewController") as! ShootingTestEditAttemptViewController
            vc.participantId = (participant?.id!)!
            vc.participantRev = (participant?.rev!)!
            self.setEditTypeLimitsTo(vc: vc, editType: nil)

            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    var participantId: Int = -1
    var isLocked = false
    var participant: ShootingTestParticipantDetailed?
    var items = Array<ShootingTestAttemptDetailed>()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.tableHeaderView = nil;
        self.tableView.tableFooterView = UIView();
        self.tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Styles.styleButton(self.addButton)
        self.addButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptListAdd"), for: .normal)

        self.updateTitle()
        self.refreshData()
    }

    func refreshUi(user: ShootingTestParticipantDetailed!) {
        self.nameLabel.text = String(format: "%@ %@", user.lastName!, user.firstName!)
        self.hunterNumberLabel.text = user.hunterNumber
        self.dateOfBirthLabel.text = ShootingTestUtil.serverDateStringToDisplayDate(serverDate: user.dateOfBirth!)

        self.addButton.isEnabled = !self.isLocked
    }

    func updateTitle() {
        let navController = self.navigationController as? RiistaNavigationController
        navController?.changeTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptListViewTitle"))
    }

    func refreshData() {
        ShootingTestManager.getParticipantDetailed(participantId: self.participantId) { (result:Any?, error:Error?) in
            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let participant = try JSONDecoder().decode(ShootingTestParticipantDetailed.self, from: json)

                    self.participant = participant
                    self.refreshUi(user: self.participant)

                    self.items.removeAll()
                    self.items.insert(contentsOf: participant.attempts!, at: 0)
                    self.tableView.reloadData()
                }
                catch {
                    print("Failed to parse <ShootingTestParticipantDetailed> item")
                }
            }
            else {
                print("getParticipantDetailed failed: " + (error?.localizedDescription)!)
            }
        }
    }

    private func setEditTypeLimitsTo(vc: ShootingTestEditAttemptViewController, editType: String?) {
        var bearCount = 0
        var mooseCount = 0
        var roeDeerCount = 0
        var bowCount = 0

        for item in items {
            if (ShootingTestAttemptDetailed.ClassConstants.TYPE_BEAR == item.type &&
                !(ShootingTestAttemptDetailed.ClassConstants.RESULT_REBATED == item.result)) {
                bearCount += 1
            }
            else if (ShootingTestAttemptDetailed.ClassConstants.TYPE_MOOSE == item.type &&
                !(ShootingTestAttemptDetailed.ClassConstants.RESULT_REBATED == item.result)) {
                mooseCount += 1
            }
            else if (ShootingTestAttemptDetailed.ClassConstants.TYPE_ROE_DEER == item.type &&
                !(ShootingTestAttemptDetailed.ClassConstants.RESULT_REBATED == item.result)) {
                roeDeerCount += 1
            }
            else if (ShootingTestAttemptDetailed.ClassConstants.TYPE_BOW == item.type &&
                !(ShootingTestAttemptDetailed.ClassConstants.RESULT_REBATED == item.result)) {
                bowCount += 1
            }
        }

        vc.enableBear = bearCount < 5 || (bearCount == 5 && ShootingTestAttemptDetailed.ClassConstants.TYPE_BEAR == editType )
        vc.enableMoose = mooseCount < 5 || (mooseCount == 5 && ShootingTestAttemptDetailed.ClassConstants.TYPE_MOOSE == editType )
        vc.enableRoeDeer = roeDeerCount < 5 || (roeDeerCount == 5 && ShootingTestAttemptDetailed.ClassConstants.TYPE_ROE_DEER == editType )
        vc.enableBow = bowCount < 5 || (bowCount == 5 && ShootingTestAttemptDetailed.ClassConstants.TYPE_BOW == editType )
    }

    // MARK - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "attemptItemCell", for: indexPath) as? UserAttemptItemCell else {
            fatalError("The dequeued cell is not an instance of UserAttemptItemCell.")
        }

        cell.cellDelegate = self
        cell.tag = indexPath.row

        let item = items[indexPath.row]

        cell.typeLabel.text = ShootingTestAttemptDetailed.localizedTypeText(value: item.type!)
        cell.resultTitleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptListResultTitle")
        cell.resultValueLabel.text = ShootingTestAttemptDetailed.localizedResultText(value: item.result!)
        cell.hitsTitleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptListHitsTitle")
        cell.hitsValueLabel.text = String(item.hits!)

        Styles.styleNegativeButton(cell.editButton)
        Styles.styleNegativeButton(cell.deleteButton)

        cell.editButton.isEnabled = !self.isLocked
        cell.deleteButton.isEnabled = !self.isLocked

        return cell
    }

    // MARK - ParticipantAttemptCellDelegate

    func didPressEdit(_ tag: Int) {
        let item = items[tag]

        let vc = self.storyboard?.instantiateViewController(withIdentifier: "editAttemptViewController") as! ShootingTestEditAttemptViewController
        vc.participantId = (self.participant?.id)!
        vc.participantRev = (self.participant?.rev)!
        vc.attemptId = item.id!
        self.setEditTypeLimitsTo(vc: vc, editType: item.type)

        self.navigationController?.pushViewController(vc, animated: true)
    }

    func didPressDelete(_ tag: Int) {
        let item = items[tag]

        let alert = MDCAlertController(title: nil,
                                       message: String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestAttemptDeleteConfirm")))
        alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK"), handler: { action in
            ShootingTestManager.deleteAttempt(attemptId: item.id!)
            { (result:Any?, error:Error?) in
                if (error == nil) {
                    self.refreshData()
                }
                else {
                    print("deleteAttempt failed: " + (error?.localizedDescription)!)
                }
            }
        }))
        alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "No"), handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
