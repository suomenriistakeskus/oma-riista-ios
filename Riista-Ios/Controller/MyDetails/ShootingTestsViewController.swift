import Foundation
import SnapKit

class ShootingTestsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    @objc var user: UserInfo?
    var items: Array<ShootingTest>?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()

        addUserNameAndHunterNumber()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        items = user?.shootingTests as? Array<ShootingTest>

        updateTitle()
        updateNoContentIndicator()
        tableView.reloadData()
    }

    private func addUserNameAndHunterNumber() {
        guard let user = user else { return }

        let stackViewContainer = UIView()
        tableView.tableHeaderView = stackViewContainer
        stackViewContainer.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }

        let stackView = UIStackView()
        stackViewContainer.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        stackView.axis = .vertical
        stackView.spacing = 4

        let label = UILabel()
        stackView.addArrangedSubview(label)
        AppTheme.shared.setupLabelFont(label: label)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .black
        label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestsNameAndHunterNumber")

        let nameAndNumber = UILabel()
        stackView.addArrangedSubview(nameAndNumber)
        AppTheme.shared.setupValueFont(label: nameAndNumber)
        nameAndNumber.numberOfLines = 0
        nameAndNumber.lineBreakMode = .byWordWrapping
        nameAndNumber.textColor = .black
        nameAndNumber.text = "\(user.firstName ?? "") \(user.lastName ?? ""), \(user.hunterNumber ?? "-")"
        nameAndNumber.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }

        // layout so that header gets the space it needs
        tableView.layoutIfNeeded()
    }

    func updateTitle() {
        let navController = self.navigationController as? RiistaNavigationController
        navController?.changeTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsTitleShootingTests"))
    }

    func updateNoContentIndicator() {
        let itemCount = items?.count ?? 0
        if (itemCount > 0) {
            addUserNameAndHunterNumber()
            return
        }

        tableView.tableHeaderView = nil

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
