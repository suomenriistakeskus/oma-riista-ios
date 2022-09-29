import UIKit
import MaterialComponents.MaterialDialogs

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
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var editButton: UIButton!

    var cellDelegate: ParticipantPaymentCellDelegate?

    @IBAction func completePressed(_ sender: UIButton) {
        self.cellDelegate?.didPressComplete(self.tag)
    }

    @IBAction func editPressed(_ sender: UIButton) {
        self.cellDelegate?.didPressEdit(self.tag)
    }
}

class ShootingTestPaymentsViewController: UIViewController, UITableViewDataSource, ParticipantPaymentCellDelegate {
    @IBOutlet weak var sumOfPaymentsLabel: UILabel!
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
        tabBarVc.fetchEvent() { (result:Any?, error:Error?) in
            self.navigationItem.rightBarButtonItem?.isEnabled = true

            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let event = try JSONDecoder().decode(ShootingTestCalendarEvent.self, from: json)

                    self.sumOfPaymentsLabel.text = String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTotalPaidAmount"),
                                                          ShootingTestUtil.currencyFormatter().string(from: event.totalPaidAmount! as NSDecimalNumber)!)
                }
                catch {
                    print("Failed to parse <ShootingTestCalendarEvent> item")
                }
            }
            else {
                print("fetchEvent failed: " + (error?.localizedDescription)!)
            }
        }
        tabBarVc.fetchParticipants() { (result:Array?, error:Error?) in
            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let participants = try JSONDecoder().decode([ShootingTestParticipantSummary].self, from: json)

                    self.items.removeAll()
                    self.items.insert(contentsOf: participants, at: 0)
                    self.items.sort(by: <)
                    self.tableView.reloadData()
                }
                catch {
                    print("Failed to parse <ShootingTestParticipantSummary> item")
                }
            }
            else {
                print("Failed to fetch participants")
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "paymentItemCell", for: indexPath) as? ParticipantPaymentsCell else {
            fatalError("The dequeued cell is not an instance of ParticipantPaymentsCell.")
        }

        cell.cellDelegate = self
        cell.tag = indexPath.row

        let item = items[indexPath.row]

        cell.titleLabel.text = String(format: "%@ %@", item.lastName!, item.firstName!)
        cell.stateView.isHidden = item.completed!
        cell.stateView.layer.cornerRadius = 3
        cell.stateView.clipsToBounds = true
        cell.stateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestStateOngoing")

        cell.totalTitleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestPaymentTotal")
        cell.paidTitleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestPaymentPaid")
        cell.remainingTitleLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestPaymentRemaining")
        cell.totalAmountLabel.text = String(format: "%ld €", item.totalDueAmount!)
        cell.paidAmountLabel.text = String(format: "%ld €", item.paidAmount!)
        cell.remainingAmountLabel.text = String(format: "%ld €", item.remainingAmount!)

        cell.bearView.refreshAttemptStateView(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBearShort"),
                                              attempts: item.attemptSummaryFor(type: ShootingTestAttemptDetailed.ClassConstants.TYPE_BEAR),
                                              intended: false)
        cell.mooseView.refreshAttemptStateView(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeMooseShort"),
                                               attempts: item.attemptSummaryFor(type: ShootingTestAttemptDetailed.ClassConstants.TYPE_MOOSE),
                                               intended: false)
        cell.deerView.refreshAttemptStateView(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeRoeDeerShort"),
                                              attempts: item.attemptSummaryFor(type: ShootingTestAttemptDetailed.ClassConstants.TYPE_ROE_DEER),
                                              intended: false)
        cell.bowView.refreshAttemptStateView(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTypeBowShort"),
                                             attempts: item.attemptSummaryFor(type: ShootingTestAttemptDetailed.ClassConstants.TYPE_BOW),
                                             intended: false)

        cell.stateView.isHidden = item.completed!
        cell.doneButton.isEnabled = !item.completed!

        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        cell.editButton.isEnabled = (tabBarVc.calendarEvent?.isOngoing())!

        item.completed! ? Styles.styleButton(cell.doneButton) : Styles.styleNegativeButton(cell.doneButton)

        Styles.styleNegativeButton(cell.editButton)

        return cell
    }

    // MARK - ParticipantPaymentCellDelegate

    func didPressComplete(_ tag: Int) {
        let item = items[tag]

        let alert = MDCAlertController(title: nil,
                                       message: String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestPaymentCompleteConfirm"), item.lastName!, item.firstName!, item.hunterNumber!))
        alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK"), handler: { action in
            ShootingTestManager.completeAllPayments(participantId: item.id!, rev: item.rev!) { (result:Any?, error:Error?) in
                if (error == nil) {
                    self.refreshData()
                }
                else {
                    print("completeAllPayments failed: " + (error?.localizedDescription)!)
                }
            }
        }))
        alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "No"), handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func didPressEdit(_ tag: Int) {
        let item = items[tag]

        let vc = self.storyboard?.instantiateViewController(withIdentifier: "editPaymentViewController") as! ShootingTestEditPaymentViewController
        vc.participantId = item.id
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
