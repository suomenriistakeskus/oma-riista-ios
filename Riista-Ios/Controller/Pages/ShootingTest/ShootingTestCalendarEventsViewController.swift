import UIKit
import OAStackView

class CalendarEventCell: UITableViewCell {
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var datetimeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var officialsLabel: UILabel!
    @IBOutlet weak var officialsView: OAStackView!
}

class ShootingTestCalendarEventsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!

    var items = Array<ShootingTestCalendarEvent>()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableHeaderView = nil
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 120;
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: animated)
        }

        updateTitle()
        fetchEvents()
    }

    func updateTitle() {
        let navController = self.navigationController as? RiistaNavigationController
        navController?.changeTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "MenuShootingTests"))
    }

    func fetchEvents() {
        ShootingTestManager.fetchShootingTestEvents() {
            (result:Array<Any>?, error:Error?) in
            if (error == nil) {
                let parsed = self.parseEvents(input: result)

                self.items.removeAll();
                self.items.insert(contentsOf: parsed, at: 0)

                self.tableView.reloadData()
            }
            else {
                print("fetchShootingTestEvents failed: " + (error?.localizedDescription)!)
            }
        }
    }

    func parseEvents(input: Array<Any>?) -> Array<ShootingTestCalendarEvent> {
        var result = Array<ShootingTestCalendarEvent>()

        do {
            let json = try JSONSerialization.data(withJSONObject: input!)
            let decodedEvents = try JSONDecoder().decode([ShootingTestCalendarEvent].self, from: json)
            result.append(contentsOf: decodedEvents)
        } catch {
            print("Failed to parse <ShootingTestCalendarEvent> items")
        }

        return result;
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "calendarItemCell", for: indexPath) as? CalendarEventCell else {
            fatalError("The dequeued cell is not an instance of CalendarEventCell.")
        }

        let item = items[indexPath.row]

        cell.typeLabel.text = ShootingTestCalendarEvent.localizedTypeText(type: item.calendarEventType!)
        cell.titleLabel.text = item.name ?? ""
        cell.datetimeLabel.text = String(format: "%@ %@ %@",
                                         ShootingTestUtil.serverDateStringToDisplayDate(serverDate: item.date!),
                                         item.beginTime!,
                                         item.endTime == nil ? "" : String(format: "- %@", item.endTime!))
        cell.addressLabel.text = String(format: "%@\n%@\n%@",
                                        item.venue?.name == nil ? "" : (item.venue?.name)!,
                                        item.venue?.address?.streetAddress ?? "",
                                        item.venue?.address?.city ?? "")

        var stateText = ""
        if (item.isClosed()) {
            stateText = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestStateClosed")
        } else if (item.isOngoing()) {
            stateText = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestStateOngoing")
        } else {
            stateText = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestStateWaiting")
        }
        cell.stateLabel.text = stateText

        cell.officialsView.axis = .vertical
        cell.officialsView.distribution = OAStackViewDistribution.equalSpacing
        cell.officialsView.alignment = OAStackViewAlignment.leading
        cell.officialsView.spacing = 5

        cell.officialsLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestOfficialsTitle")
        cell.officialsView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        for official : ShootingTestOfficial in item.officials! {
            let label = UILabel()
            label.font = label.font.withSize(AppConstants.Font.LabelMedium)
            label.text = String(format: "%@ %@", official.firstName!, official.lastName!)
            cell.officialsView.addArrangedSubview(label)
        }

        cell.officialsView.translatesAutoresizingMaskIntoConstraints = false

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]

        let sb = UIStoryboard.init(name: "ShootingTest", bundle: nil)
        let destination = sb.instantiateInitialViewController() as! ShootingTestTabBarViewController
        destination.setSelectedEvent(calendarEventId: item.calendarEventId!, eventId: item.shootingTestEventId)

        let segue = UIStoryboardSegue.init(identifier: "", source: self, destination: destination, performHandler: {
            self.navigationController?.pushViewController(destination, animated: true)
            })

        segue.perform()
    }
}
