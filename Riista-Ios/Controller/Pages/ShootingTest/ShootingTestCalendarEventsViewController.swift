import UIKit
import RiistaCommon

class CalendarEventCell: UITableViewCell {
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var datetimeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var officialsLabel: UILabel!
    @IBOutlet weak var officialsView: UIStackView!
}

class ShootingTestCalendarEventsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!

    private lazy var logger = AppLogger(for: self, printTimeStamps: false)
    private static let stringProvider = LocalizedStringProvider()

    private var items = [CommonShootingTestCalendarEvent]()

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

        title = "MenuShootingTests".localized()
        fetchEvents()
    }

    func fetchEvents() {
        RiistaSDK.shared.shootingTestContext.fetchShootingTestCalendarEvents(
            completionHandler: handleOnMainThread { [weak self] result, _ in
                guard let self = self else { return }

                if let successResult = result as? OperationResultWithDataSuccess,
                   let shootingTestEvents = successResult.data as? [CommonShootingTestCalendarEvent] {
                    self.logger.v { "Fetched shooting test events!" }

                    self.items = shootingTestEvents
                    self.tableView.reloadData()
                } else {
                    self.logger.w { "Failed to fetch shooting test events" }
                }
            }
        )
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

        cell.typeLabel.text = item.calendarEventType?.value?.localizedName ??
            item.calendarEventType?.rawBackendEnumValue ?? ""

        cell.titleLabel.text = item.name ?? ""

        cell.datetimeLabel.text = item.formattedDateAndTime
        cell.addressLabel.text = String(format: "%@\n%@\n%@",
                                        item.venue?.name ?? "",
                                        item.venue?.address?.streetAddress ?? "",
                                        item.venue?.address?.city ?? "")

        cell.stateLabel.text = item.state.localized(stringProvider: Self.stringProvider)

        cell.officialsView.axis = .vertical
        cell.officialsView.distribution = .equalSpacing
        cell.officialsView.alignment = .leading
        cell.officialsView.spacing = 5

        cell.officialsLabel.text = "ShootingTestOfficialsTitle".localized()
        cell.officialsView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        item.officials?.forEach { official in
            let label = UILabel().configure(for: .label)
            label.text = String(format: "%@ %@",
                                official.firstName ?? "",
                                official.lastName ?? "")
            cell.officialsView.addArrangedSubview(label)
        }

        cell.officialsView.translatesAutoresizingMaskIntoConstraints = false

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        guard let calendarEventId = item.calendarEventId?.int64Value else { return }

        let sb = UIStoryboard.init(name: "ShootingTest", bundle: nil)
        let destination = sb.instantiateInitialViewController() as! ShootingTestTabBarViewController

        destination.shootingTestManager.setSelectedEvent(
            calendarEventId: calendarEventId,
            shootingTestEventId: item.shootingTestEventId?.int64Value
        )

        let segue = UIStoryboardSegue.init(identifier: "", source: self, destination: destination, performHandler: {
            self.navigationController?.pushViewController(destination, animated: true)
            })

        segue.perform()
    }
}
