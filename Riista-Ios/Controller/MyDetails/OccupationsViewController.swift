import Foundation

class OccupationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    @objc var user: UserInfo?
    var items: Array<Occupation>?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        items = user?.occupations as? Array<Occupation>

        title = "MyDetailsAssignmentsTitle".localized()
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: OccupationsCell = tableView.dequeueReusableCell(withIdentifier: "userOccupationCell") as! OccupationsCell

        let occupationItem = items![indexPath.row]
        cell.setup(item: occupationItem, langCode: RiistaSettings.language())

        return cell
    }
}
