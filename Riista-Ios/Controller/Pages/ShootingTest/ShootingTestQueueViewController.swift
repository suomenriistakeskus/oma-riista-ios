import UIKit
import RiistaCommon


class ParticipantQueueCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bearView: ShootingTestAttemptStateView!
    @IBOutlet weak var mooseView: ShootingTestAttemptStateView!
    @IBOutlet weak var deerView: ShootingTestAttemptStateView!
    @IBOutlet weak var bowView: ShootingTestAttemptStateView!
}

class ShootingTestQueueViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
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
        self.tableView.delegate = self
        self.tableView.tableHeaderView = nil;
        self.tableView.tableFooterView = UIView();
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

        tabBarVc.refreshEvent()
        tabBarVc.shootingTestManager.listParticipantsForEvent { participants, error in
            if let participants = participants {
                self.participants = participants
                    .filter { participant in
                        participant.completed == false
                    }.sorted(by: { lhs, rhs in
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "queueItemCell", for: indexPath) as? ParticipantQueueCell else {
            fatalError("The dequeued cell is not an instance of ParticipantQueueCell.")
        }

        let participant = participants[indexPath.row]

        if let hunterNumber = participant.hunterNumber {
            cell.titleLabel.text = "\(participant.formattedFullNameLastFirst), \(hunterNumber)"
        } else {
            cell.titleLabel.text = participant.formattedFullNameLastFirst
        }

        cell.bearView.refreshAttemptStateView(
            title: "ShootingTestTypeBearShort".localized(),
            attempt: participant.attemptSummaryFor(type: .bear),
            intended: participant.bearTestIntended
        )
        cell.mooseView.refreshAttemptStateView(
            title: "ShootingTestTypeMooseShort".localized(),
            attempt: participant.attemptSummaryFor(type: .moose),
            intended: participant.mooseTestIntended
        )
        cell.deerView.refreshAttemptStateView(
            title: "ShootingTestTypeRoeDeerShort".localized(),
            attempt: participant.attemptSummaryFor(type: .roeDeer),
            intended: participant.deerTestIntended
        )
        cell.bowView.refreshAttemptStateView(
            title: "ShootingTestTypeBowShort".localized(),
            attempt: participant.attemptSummaryFor(type: .bow),
            intended: participant.bowTestIntended
        )

        return cell
    }

    // MARK - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let shootingTestManager = (self.tabBarController as? ShootingTestTabBarViewController)?.shootingTestManager else {
            return
        }

        let participant = participants[indexPath.row]

        let vc = self.storyboard?.instantiateViewController(withIdentifier: "userAttemptsViewController") as! ShootingTestUserAttemptsViewController
        vc.shootingTestManager = shootingTestManager
        vc.participantId = participant.id
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
