import Foundation

@objc public class InstructionsCell: UITableViewCell {
    @IBOutlet weak var instructionsImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
}

@objc public class Instructions: NSObject {
    @objc var titleText: String = ""
    @objc var detailsText: String = ""
    @objc var image: UIImage? = nil

    public init(titleText: String, detailsText: String, image: UIImage?) {
        self.titleText = titleText
        self.detailsText = detailsText
        self.image = image
    }

    // allow creating empty Instructions
    public override init() {
    }
}

@objc public class InstructionsViewController: UITableViewController {

    @objc var instructionsItems = [Instructions]() {
        didSet {
            tableView.reloadData()
        }
    }

    public override func viewDidLoad() {
        configureTableView()
        configureNavBarAppearance()
        configureDismissal()
    }

    private func configureTableView() {
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension
    }

    private func configureNavBarAppearance() {
        guard let navigationBar = self.navigationController?.navigationBar else { return }

        if var titleTextAttributes: [NSAttributedString.Key : Any] = navigationBar.titleTextAttributes {
            titleTextAttributes[.font] = UIFont.appFont(for: .navigationBar)
            navigationBar.titleTextAttributes = titleTextAttributes
        }
    }

    private func configureDismissal() {
        let closeImage = UIImage(named: "close_white_24pt")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: closeImage, style: .plain,
                                                                 target: self, action: #selector(onDismissClicked))
    }

    @objc public func onDismissClicked() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource implementation

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return instructionsItems.count
    }

    // MARK: - UITableViewDelegate implementation

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "instructionsCell", for: indexPath) as? InstructionsCell else {
            fatalError("The dequeued cell is not an instance of InstructionsCell.")
        }

        let instructions = instructionsItems[indexPath.row]
        cell.titleLabel.font = cell.titleLabel.font.appFontWithSameAttributes()
        cell.detailsLabel.font = cell.detailsLabel.font.appFontWithSameAttributes()

        cell.titleLabel.text = instructions.titleText
        cell.detailsLabel.text = instructions.detailsText
        if let image = instructions.image {
            cell.instructionsImage.image = image
            cell.instructionsImage.isHidden = false
        } else {
            cell.instructionsImage.isHidden = true
        }
        return cell
    }
}
