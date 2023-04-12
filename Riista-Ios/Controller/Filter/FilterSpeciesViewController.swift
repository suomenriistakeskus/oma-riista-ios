import Foundation
import MaterialComponents
import RiistaCommon

protocol FilterSpeciesViewControllerDelegate: AnyObject {
    func onFilterSpeciesSelected(species: [RiistaCommon.Species])
}

class FilterSpeciesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var clearButton: MDCButton!
    @IBOutlet weak var allButton: MDCButton!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var okButton: MDCButton!

    var delegate: FilterSpeciesViewControllerDelegate?

    var categoryId: Int = -1
    var isSrva = false

    private var tableViewItems = [RiistaSpecies?]()

    override func viewDidLoad() {
        clearButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "FilterClearSelections"), for: .normal)
        clearButton.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)

        allButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "FilterSelectAll"), for: .normal)
        allButton.addTarget(self, action: #selector(didTapSelectAll), for: .touchUpInside)

        okButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK"), for: .normal)
        okButton.addTarget(self, action: #selector(didTapOk), for: .touchUpInside)

        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.applicationColor(GreyLight)

        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.rightBarButtonItem = nil

        let languageCode = RiistaSettings.language()
        var speciesList: [RiistaSpecies?]

        if (isSrva) {
            self.title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "SRVA")

            let srvaMetadata = RiistaSDK.shared.metadataProvider.srvaMetadata
            speciesList = srvaMetadata.species.map { knownSpecies in
                RiistaGameDatabase.sharedInstance().species(byId: Int(knownSpecies.speciesCode))
            }
        }
        else {
            let categories = RiistaGameDatabase.sharedInstance()?.categories as! [Int : RiistaSpeciesCategory]
            self.title = categories[categoryId]?.name[RiistaSettings.language()] as? String

            speciesList = RiistaGameDatabase.sharedInstance()?.speciesList(withCategoryId: categoryId) as! [RiistaSpecies]
        }

        tableViewItems = speciesList.sorted(by: {$1?.name[languageCode!] as! String > $0?.name[languageCode!] as! String})

        if (isSrva) {
            tableViewItems.append(nil)
        }

        refreshOkButton()
    }

    // Mark UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterSpeciesCell") as! FilterSpeciesCell
        cell.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: (cell.frame.size.height))

        if let item = tableViewItems[indexPath.row] {
            cell.speciesImage.image = ImageUtils.loadSpeciesImage(speciesCode: item.speciesId)
            cell.speciesName.text = RiistaUtils.name(withPreferredLanguage: item.name)
        } else {
            // SRVA "other" species
            cell.speciesImage.image = UIImage.init(named: "unknown_white")?.withRenderingMode(.alwaysTemplate)
            cell.speciesImage.tintColor = UIColor.black
            cell.speciesName.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "SrvaOtherSpeciesDescription")
        }

        let selectedIndexPaths = tableView.indexPathsForSelectedRows
        if (selectedIndexPaths != nil && selectedIndexPaths!.contains(indexPath)) {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }

        refreshOkButton()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }

        refreshOkButton()
    }

    // Mark Button actions

    @objc func didTapClear(sender: Any) {
        if let selected = tableView.indexPathsForSelectedRows {
            for indexPath in selected {
                tableView.deselectRow(at: indexPath, animated: true)
            }

            tableView.reloadData()
        }

        refreshOkButton()
    }

    @objc func didTapSelectAll(sender: Any) {
        selectAllRows()

        // visible rows are not affected by selectAllRows -> update manually
        if let visibleRows = tableView.indexPathsForVisibleRows {
            for indexPath in visibleRows {
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.accessoryType = .checkmark
                }
            }
        }

        refreshOkButton()
    }

    @objc func didTapOk(sender: Any) {
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows else {
            selectAllRows()
            return
        }

        // Ok tap without any selections confirms all species ids in category
        if (selectedIndexPaths.count == 0) {
            selectAllRows()
        }

        var selectedSpecies = [RiistaCommon.Species]()

        for indexPath in selectedIndexPaths {
            let species = tableViewItems[indexPath.row]
            if (species == nil) {
                selectedSpecies.append(Species.Other())
            }
            else {
                selectedSpecies.append(Species.Known(speciesCode: Int32(species!.speciesId)))
            }
        }

        delegate?.onFilterSpeciesSelected(species: selectedSpecies)

        if let vcStack = navigationController?.viewControllers {
            // Pop both category and species views or just species view for SRVA case
            navigationController?.popToViewController(vcStack[vcStack.count - (vcStack.count >= 3 ? 3 : 2)], animated: true)
        }
    }

    // Mark Utils

    // Does not refresh views
    func selectAllRows() {
        let totalRows = tableView.numberOfRows(inSection: 0)
        for row in 0..<totalRows {
            tableView.selectRow(at: NSIndexPath(row: row, section: 0) as IndexPath, animated: true, scrollPosition: .none)
        }
    }

    func refreshOkButton() {
        if let selectedCount = tableView.indexPathsForSelectedRows?.count {
            let title = String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "FilterConfirmWithAmount"),
                               selectedCount)
            okButton.setTitle(title, for: .normal)
        }
        else {
            okButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "FilterConfirmNoSelected"), for: .normal)
        }
    }
}

class FilterSpeciesCell: UITableViewCell {
    @IBOutlet weak var speciesImage: UIImageView!
    @IBOutlet weak var speciesName: UILabel!
}
