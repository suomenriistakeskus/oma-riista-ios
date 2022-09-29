import UIKit

class ParticipantQueueCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bearView: ShootingTestAttemptStateView!
    @IBOutlet weak var mooseView: ShootingTestAttemptStateView!
    @IBOutlet weak var deerView: ShootingTestAttemptStateView!
    @IBOutlet weak var bowView: ShootingTestAttemptStateView!
}

class ShootingTestQueueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!

    var items = Array<ShootingTestParticipantSummary>()

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
        tabBarVc.fetchParticipants() { (result:Array?, error:Error?) in
            self.navigationItem.rightBarButtonItem?.isEnabled = true

            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let participants = try JSONDecoder().decode([ShootingTestParticipantSummary].self, from: json)

                    self.items.removeAll()
                    self.items.insert(contentsOf: participants.filter { $0.completed == false }, at: 0)
                    self.items.sort(by: <)
                    self.tableView.reloadData()
                }
                catch {
                    print("Failed to parse <ShootingTestParticipantSummary> item")
                }
            }
            else {
                print("listParticipantsForEvent failed: " + (error?.localizedDescription)!)
            }
        }
    }

    // MARK - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "queueItemCell", for: indexPath) as? ParticipantQueueCell else {
            fatalError("The dequeued cell is not an instance of ParticipantQueueCell.")
        }

        let item = items[indexPath.row]

        cell.titleLabel.text = String(format: "%@ %@", item.lastName!, item.firstName!)

        cell.bearView.refreshAttemptStateView(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBearShort"),
                                              attempts: item.attemptSummaryFor(type: ShootingTestAttemptDetailed.ClassConstants.TYPE_BEAR),
                                              intended: item.bearTestIntended)
        cell.mooseView.refreshAttemptStateView(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeMooseShort"),
                                               attempts: item.attemptSummaryFor(type: ShootingTestAttemptDetailed.ClassConstants.TYPE_MOOSE),
                                               intended: item.mooseTestIntended)
        cell.deerView.refreshAttemptStateView(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeRoeDeerShort"),
                                              attempts: item.attemptSummaryFor(type: ShootingTestAttemptDetailed.ClassConstants.TYPE_ROE_DEER),
                                              intended: item.deerTestIntended)
        cell.bowView.refreshAttemptStateView(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBowShort"),
                                             attempts: item.attemptSummaryFor(type: ShootingTestAttemptDetailed.ClassConstants.TYPE_BOW),
                                             intended: item.bowTestIntended)

        return cell
    }

    // MARK - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]

        let vc = self.storyboard?.instantiateViewController(withIdentifier: "userAttemptsViewController") as! ShootingTestUserAttemptsViewController
        vc.participantId = item.id!
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
