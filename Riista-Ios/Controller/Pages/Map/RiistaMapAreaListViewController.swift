import Foundation
import MaterialComponents.MaterialDialogs
import MaterialComponents.MaterialTextControls_UnderlinedTextFields

struct AreaListItem {
    var areaType: AppConstants.AreaType?
    var clubArea: RiistaClubAreaMap?
    var mhArea: AreaMap?
    var canRemove: Bool = false
}

class AreaListItemCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var removeButton: MaterialButton!
}

class RiistaMapAreaListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MDCAlertControllerDelegate {
    @IBOutlet weak var filterInput: MDCUnderlinedTextField!
    @IBOutlet weak var areaCodeButton: MDCButton!
    @IBOutlet weak var tableView: UITableView!

    static let MIN_AREA_CODE_LENGTH = 10

    var addAreaAlertController: MDCAlertController?
    var areaTextField: MDCUnderlinedTextField?
    var addAreaAction: MDCAlertAction?

    var clubAreaManager: RiistaClubAreaMapManager?

    var areaType: AppConstants.AreaType?
    var allItems = Array<AreaListItem>()
    var visibleItems = Array<AreaListItem>()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableHeaderView = nil
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableView.automaticDimension

        self.filterInput.configure(for: .inputValue)
        self.filterInput.delegate = self
        self.filterInput.label.text = "MapAreaFilterHint".localized()
        self.filterInput.leftViewMode = .always
        self.filterInput.leftView = UIImageView(image: UIImage(named: "search"))
        self.filterInput.clearButtonMode = .whileEditing
        self.filterInput.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        AppTheme.shared.setupPrimaryButtonTheme(button: self.areaCodeButton)
        self.areaCodeButton.titleEdgeInsets = UIEdgeInsets(top: self.areaCodeButton.titleEdgeInsets.top,
                                                           left: -10.0,
                                                           bottom: self.areaCodeButton.titleEdgeInsets.bottom,
                                                           right: -10.0)
        self.areaCodeButton.addTarget(self, action: #selector(onAreaCodeClick), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.areaCodeButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingAddWithAreaCode"), for: .normal)
        self.areaCodeButton.isHidden = (areaType != AppConstants.AreaType.Seura)

        title = "MapSettingSelectArea".localized()
        refreshData()
    }

    @objc func setAreaType(type: AppConstants.AreaType) {
        self.areaType = type
    }

    @objc private func textFieldDidChange(textField: UITextField) {
        if (textField == filterInput) {
            filterList(text: textField.text)
        } else if (textField == areaTextField) {
            let areaCanBeAdded = (textField.text?.count ?? 0) >= RiistaMapAreaListViewController.MIN_AREA_CODE_LENGTH
            setAddAreaButton(enabled: areaCanBeAdded)
        }
    }

    private func setAddAreaButton(enabled: Bool) {
        if let addAreaAlertController = addAreaAlertController, let addAreaAction = addAreaAction {
            let confirmButton = addAreaAlertController.button(for: addAreaAction)
            confirmButton?.isEnabled = enabled
        }
    }

    private func filterList(text: String?) {
        self.visibleItems.removeAll()

        if ((text ?? "").isEmpty) {
            self.visibleItems.append(contentsOf: self.allItems)
        } else {
            let searchText = text!.lowercased()

            for item: AreaListItem in self.allItems {
                if (item.areaType == AppConstants.AreaType.Seura) {
                    let clubName = RiistaUtils.getLocalizedString(item.clubArea?.club)?.lowercased() ?? ""
                    let areaName = RiistaUtils.getLocalizedString(item.clubArea?.name)?.lowercased() ?? ""
                    let areaId = item.clubArea?.externalId?.lowercased() ?? ""

                    if (clubName.contains(searchText) || areaName.contains(searchText) || areaId.contains(searchText)) {
                        self.visibleItems.append(item)
                    }
                }
                else if (item.areaType == AppConstants.AreaType.Moose || item.areaType == AppConstants.AreaType.Pienriista) {
                    if ((item.mhArea?.getAreaName()?.lowercased().contains(searchText))! || (item.mhArea?.getAreaNumberAsString().contains(searchText))!) {
                        self.visibleItems.append(item)
                    }
                }
            }
        }
        self.tableView.reloadData()
    }

    func refreshData() {
        switch self.areaType! {
        case AppConstants.AreaType.Moose:
            MapAreaManager.fetchMooseAreaMaps(completion: { (result: Array?, error: Error?) in
                if (error == nil) {
                    do {
                        let json = try JSONSerialization.data(withJSONObject: result!)
                        let areas = try JSONDecoder().decode([AreaMap].self, from: json)

                        self.allItems.removeAll()
                        for item: AreaMap in areas {
                            var area = AreaListItem()
                            area.areaType = AppConstants.AreaType.Moose
                            area.mhArea = item
                            area.canRemove = false
                            self.allItems.append(area)
                        }
                        self.sortItems()
                        self.filterList(text: self.filterInput.text)
                    }
                    catch {
                        print("Failed to parse moose [AreaMap]")
                    }
                }
                else {
                    print ("fetchMooseAreaMaps failed: " + (error?.localizedDescription)!)
                }
            })
            break
        case AppConstants.AreaType.Pienriista:
            MapAreaManager.fetchPienriistaAreaMaps(completion: { (result: Array?, error: Error?) in
                if (error == nil) {
                    do {
                        let json = try JSONSerialization.data(withJSONObject: result!)
                        let areas = try JSONDecoder().decode([AreaMap].self, from: json)

                        self.allItems.removeAll()
                        for item: AreaMap in areas {
                            var area = AreaListItem()
                            area.areaType = AppConstants.AreaType.Pienriista
                            area.mhArea = item
                            area.canRemove = false
                            self.allItems.append(area)
                        }
                        self.sortItems()
                        self.filterList(text: self.filterInput.text)
                    }
                    catch {
                        print("Failed to parse pienriista [AreaMap]")
                    }
                }
                else {
                    print ("fetchPienriistaAreaMaps failed: " + (error?.localizedDescription)!)
                }
            })
            break
        case AppConstants.AreaType.Seura:
            refreshClubAreas()
            break
        default:
            break
        }
    }

    func refreshClubAreas() {
        if (self.clubAreaManager == nil) {
            clubAreaManager = RiistaClubAreaMapManager()
        }

        self.clubAreaManager?.fetchMaps({
            self.allItems.removeAll()

            let areas = self.clubAreaManager?.getVisibleMaps()

            for item in areas! {
                let clubArea = item as? RiistaClubAreaMap
                var area = AreaListItem()
                area.areaType = AppConstants.AreaType.Seura
                area.clubArea = clubArea
                area.canRemove = clubArea?.manuallyAdded == true
                self.allItems.append(area)
            }

            self.sortItems()
            self.filterList(text: self.filterInput.text)
        })
    }

    private func sortItems() {
        if (self.areaType == AppConstants.AreaType.Seura) {
            self.allItems = self.allItems.sorted(by: {RiistaUtils.getLocalizedString($0.clubArea?.club) < RiistaUtils.getLocalizedString($1.clubArea?.club)})
        }
        else if (self.areaType == AppConstants.AreaType.Moose || self.areaType == AppConstants.AreaType.Pienriista) {
            self.allItems = self.allItems.sorted(by: { $0.mhArea!.getAreaNumberAsString() < $1.mhArea!.getAreaNumberAsString() })
        }
    }

    private func confirmDeleteArea(externalId: String) {
        let alert = MDCAlertController(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapRemoveAreaTitle"),
                                       message: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapRemoveAreaConfirm"))
        alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "Cancel", value: nil), handler: nil))
        let deleteAction = MDCAlertAction(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapRemoveArea"),
            handler: { [weak self] _ in
                self?.deleteArea(externalId: externalId)
            }
        )
        alert.addAction(deleteAction)

        present(alert, animated: true, completion: nil)
    }

    private func deleteArea(externalId: String) {
        if (RiistaSettings.activeClubAreaMapId() == externalId) {
            RiistaSettings.setActiveClubAreaMapId(nil)
        }

        self.clubAreaManager?.removeManualMap(externalId)
        self.refreshData()
    }

    @objc private func onAreaCodeClick(_: UIButton) {
        let alert = MDCAlertController(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapAddArea"),
                                       message: "")
        self.addAreaAlertController = alert

        alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "Cancel"),
                                       handler: nil))
        let addAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK"),
                                       handler: { action -> Void in
            let input = alert.accessoryView as! MDCUnderlinedTextField
            self.addNewArea(areaCode: input.text!);

            self.addAreaAlertController = nil
            self.addAreaAction = nil
            self.areaTextField = nil
        })
        self.addAreaAction = addAction
        alert.addAction(addAction)

        if let button = alert.button(for: addAction) {
            button.setTitleColor(.black, for: .normal)
            button.setTitleColor(UIColor.applicationColor(RiistaApplicationColorTextDisabled), for: .disabled)
            button.isEnabled = false
        }

        areaTextField = {
            let textField = MDCUnderlinedTextField().configure(for: .inputValue)
            textField.label.text = "MapAreaCode".localized()
            textField.autocapitalizationType = .allCharacters
            textField.returnKeyType = UIReturnKeyType.done
            textField.delegate = self

            textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
            return textField
        }()

        alert.accessoryView = areaTextField

        alert.delegate = self

        self.present(alert, animated: true, completion: nil)
    }

    func alertController(_ alertController: MDCAlertController, willAppear animated: Bool) {
        setAddAreaButton(enabled: false)
    }

    private func addNewArea(areaCode: String) {
        if (areaCode.count < RiistaMapAreaListViewController.MIN_AREA_CODE_LENGTH) {
            return
        }

        let network = RiistaNetworkManager.sharedInstance()
        network?.clubAreaMap(areaCode, completion: { (item: Dictionary?, error: Error?) in
            if (error != nil) {
                self.showErrorDialog(message: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapAddAreaError"))
            }
            else {
                let map = RiistaClubAreaMap.init(dict: item)
                map?.manuallyAdded = true

                if ((map?.externalId) != nil) {
                    self.clubAreaManager!.addManualMap(map)
                    RiistaSettings.setActiveClubAreaMapId(map?.externalId)
                    self.navigationController?.popViewController(animated: true)
                }
                else {
                    if (error != nil) {
                        self.showErrorDialog(message: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapAddAreaError"))
                    }
                }
            }
        })
    }

    private func showErrorDialog(message: String) {
        let alertController = MDCAlertController(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "Error"),
                                                 message: message)
        let action = MDCAlertAction(title:RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK")) { (action) in
            // Do nothing
        }
        alertController.addAction(action)

        present(alertController, animated:true, completion:nil)
    }

    // MARK - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "areaMapItemCell", for: indexPath) as? AreaListItemCell else {
            fatalError("The dequeued cell is not an instance of AreaMapItemCell.")
        }

        cell.tag = indexPath.row

        let item = visibleItems[indexPath.row]

        if (item.areaType == AppConstants.AreaType.Seura) {
            cell.titleLabel.text = RiistaUtils.getLocalizedString(item.clubArea?.club)
            let areaName = RiistaUtils.getLocalizedString(item.clubArea?.name) ?? ""
            if (areaName.isEmpty) {
                cell.nameLabel.isHidden = true
            } else {
                cell.nameLabel.isHidden = false
                cell.nameLabel.text = areaName
            }

            let areaId = item.clubArea?.externalId ?? ""
            // don't show id if already has the same information
            if (areaName == areaId || areaId.isEmpty) {
                cell.idLabel.isHidden = true
            } else {
                cell.idLabel.text = String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapAreaCodeFormat"), areaId)
                cell.idLabel.isHidden = false
            }

            if (item.canRemove && !areaId.isEmpty) {
                cell.removeButton.isHidden = false
                cell.removeButton.applyTextTheme(withScheme: AppTheme.shared.buttonContainerScheme())
                cell.removeButton.onClicked = {
                    self.confirmDeleteArea(externalId: areaId)
                }
            } else {
                cell.removeButton.isHidden = true
            }
        }
        else if (item.areaType == AppConstants.AreaType.Moose || item.areaType == AppConstants.AreaType.Pienriista) {
            cell.titleLabel.text = item.mhArea?.getAreaNumberAsString()
            cell.nameLabel.text = item.mhArea?.getAreaName()
            cell.idLabel.isHidden = true
            cell.removeButton.isHidden = true
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = visibleItems[indexPath.row]

        switch self.areaType! {
        case AppConstants.AreaType.Pienriista:
            RiistaSettings.setSelectedPienriistaArea(item.mhArea)
            break
        case AppConstants.AreaType.Moose:
            RiistaSettings.setSelectedMooseArea(item.mhArea)
            break
        case AppConstants.AreaType.Seura:
            RiistaSettings.setActiveClubAreaMapId(item.clubArea?.externalId)
            break
        default:
            print("Area type not set")
        }

        self.navigationController?.popViewController(animated: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.filterInput.resignFirstResponder()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == filterInput) {
            self.filterInput.resignFirstResponder()
            return true
        } else if (textField == areaTextField) {

            if let textLength = textField.text?.count,
                textLength >= RiistaMapAreaListViewController.MIN_AREA_CODE_LENGTH {
                textField.resignFirstResponder()
                self.addAreaAlertController?.dismiss(animated: true, completion: {
                    self.addNewArea(areaCode: textField.text!);
                })
            }
            return true
        }
        return false
    }
}
