import Foundation

class ShootingTestsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    @objc var user: UserInfo?
    var items: Array<ShootingTest>?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        items = user?.shootingTests as? Array<ShootingTest>

        updateTitle()
        updateNoContentIndicator()
        tableView.reloadData()
    }

    func updateTitle() {
        let navController = self.navigationController as? RiistaNavigationController
        navController?.changeTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsTitleShootingTests"))
    }

    func updateNoContentIndicator() {
        let itemCount = items?.count ?? 0
        if (itemCount > 0) {
            tableView.tableHeaderView = nil
            return
        }

        let label = UILabel()
        label.font = label.font.withSize(AppConstants.Font.LabelMedium)
        label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsNoShootingTestAttempts")
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let bgView = UIView()
        bgView.contentMode = .center
        bgView.addSubview(label)

        label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: bgView.centerXAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 20).isActive = true
        label.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -20).isActive = true

        tableView.backgroundView = bgView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ShootingTestCell = tableView.dequeueReusableCell(withIdentifier: "userShootingTestCell") as! ShootingTestCell

        let shootingTestItem = items![indexPath.row]
        cell.setup(item: shootingTestItem)

        return cell
    }
}
