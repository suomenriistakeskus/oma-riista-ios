import Foundation

class MhPermitItemCell: UITableViewCell {
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var permitTitleLabel: UILabel!
    @IBOutlet weak var permitAreaLabel: UILabel!
    @IBOutlet weak var permitNameLabel: UILabel!
    @IBOutlet weak var permitTimeLabel: UILabel!
}

class MhPermitListViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    lazy var fetchedResultsController: NSFetchedResultsController<MhPermit> = {
        let appDelegate = UIApplication.shared.delegate as! RiistaAppDelegate
        let managedContext = appDelegate.managedObjectContext

        let fetchRequest = NSFetchRequest<MhPermit>(entityName: "MhPermit")
        let beginSort = NSSortDescriptor(key: "beginDate", ascending: false)
        let endSort = NSSortDescriptor(key: "endDate", ascending: false)
        fetchRequest.sortDescriptors = [beginSort, endSort]

        let fetchedResultsController = NSFetchedResultsController<MhPermit>(fetchRequest: fetchRequest, managedObjectContext: managedContext!, sectionNameKeyPath: nil, cacheName: nil)

        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 120
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.tableHeaderView = nil

        self.refreshControl?.attributedTitle = NSAttributedString(string: "")
        self.refreshControl?.addTarget(self, action: #selector(pullToRefresh(sender:)), for: UIControl.Event.valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateTitle()
        refreshData()
    }

    func updateTitle() {
        let navController = self.navigationController as? RiistaNavigationController
        navController?.changeTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "MyDetailsMhPermitsTitle"))
    }

    func refreshData() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to fetch MH permits")
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = fetchedResultsController.fetchedObjects else { return 0 }
        return  items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "mhPermitItemCell", for: indexPath) as? MhPermitItemCell else {
            fatalError("The dequeued cell is not an instance of MhPermitItemCell.")
        }

        cell.tag = indexPath.row

        let item = fetchedResultsController.object(at: indexPath)

        self.addBordersForCell(cell: cell)

        let language = RiistaSettings.language()
        cell.permitTitleLabel.text = MhPermit.getLocalizedPermitTypeAndIdentifier(permit: item, languageCode: language)
        cell.permitAreaLabel.text = item.getAreaNumberAndName(languageCode: language)
        cell.permitNameLabel.text = item.getPermitName(languageCode: language)
        cell.permitTimeLabel.text = MhPermit.getPeriod(permit: item)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = fetchedResultsController.object(at: indexPath)

        let controller = self.storyboard!.instantiateViewController(withIdentifier: "MhPermitDetailsController") as! MhPermitDetailsViewController
        controller.item = item
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func addBordersForCell(cell: MhPermitItemCell)
    {
        cell.cardView.layer.borderColor = UIColor.applicationColor(RiistaApplicationColorDiaryCellBorder)?.cgColor
        cell.cardView.layer.borderWidth = 1.0
        cell.cardView.layer.cornerRadius = 5.0
    }

    @objc func pullToRefresh(sender:AnyObject) {
        MhPermitSync.shared.sync(completion: {_,_ in
            // Ignore any errors

            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        })
    }
}
