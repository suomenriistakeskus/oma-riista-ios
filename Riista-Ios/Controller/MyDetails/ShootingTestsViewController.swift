import Foundation
import SnapKit
import RiistaCommon

class ShootingTestsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    private lazy var logger = AppLogger(for: self, printTimeStamps: false)

    @IBOutlet weak var tableView: UITableView!

    private var shootingTests = [RiistaCommon.ShootingTest]()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()

        addUserNameAndHunterNumber()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        title = "MyDetailsTitleShootingTests".localized()

        refreshUserShootingTests()
    }

    private func refreshUserShootingTests() {
        if let userInformation = RiistaSDK.shared.currentUserContext.userInformation {
            self.shootingTests = userInformation.shootingTests
        } else {
            logger.v { "No user info, nothing to show?" }
            self.shootingTests.removeAll()
        }

        updateNoContentIndicator()
        tableView.reloadData()
    }

    private func addUserNameAndHunterNumber() {
        guard let userInformation = RiistaSDK.shared.currentUserContext.userInformation else {
            logger.w { "No user info, cannot display user name and hunter number" }
            return
        }

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

        let label = UILabel().configure(for: .label)
        stackView.addArrangedSubview(label)
        label.lineBreakMode = .byTruncatingTail
        label.text = "ShootingTestsNameAndHunterNumber".localized()

        let nameAndNumber = UILabel().configure(for: .inputValue, numberOfLines: 0)
        stackView.addArrangedSubview(nameAndNumber)
        nameAndNumber.lineBreakMode = .byWordWrapping
        nameAndNumber.textColor = .black
        nameAndNumber.text = "\(userInformation.firstName) \(userInformation.lastName), \(userInformation.hunterNumber ?? "-")"
        nameAndNumber.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }

        // layout so that header gets the space it needs
        tableView.layoutIfNeeded()
    }

    func updateNoContentIndicator() {
        if (shootingTests.count > 0) {
            addUserNameAndHunterNumber()
            return
        }

        tableView.tableHeaderView = nil

        let label = UILabel().configure(for: .label)
        label.text = "MyDetailsNoShootingTestAttempts".localized()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
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
        return shootingTests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ShootingTestCell = tableView.dequeueReusableCell(withIdentifier: "userShootingTestCell") as! ShootingTestCell

        if let shootingTest = shootingTests.getOrNil(index: indexPath.row) {
            cell.setup(shootingTest: shootingTest)
        } else {
            cell.clearValues()
        }

        return cell
    }
}
