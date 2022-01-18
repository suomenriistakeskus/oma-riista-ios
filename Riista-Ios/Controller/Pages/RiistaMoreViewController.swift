import Foundation
import MaterialComponents

fileprivate enum MoreItemType {
    case myDetails
    case gallery
    case contactDetails
    case shootingTests
    case settings
    case huntingDirector
    case eventSearch
    case magazine
    case seasons
    case logout
}

fileprivate struct MoreItem {
    let type: MoreItemType
    let iconResource: String
    let titleResource: String
    let opensInBrowser: Bool

    init(_ type: MoreItemType, iconResource: String, titleResource: String, opensInBrowser: Bool = false) {
        self.type = type
        self.iconResource = iconResource
        self.titleResource = titleResource
        self.opensInBrowser = opensInBrowser
    }
}

@objc class MoreItemCell: UITableViewCell {
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var opensInBrowserIndicator: UIImageView!

    fileprivate func setup(item: MoreItem) {
        iconView.image = UIImage(named: item.iconResource)
        titleView.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: item.titleResource)

        if (item.opensInBrowser) {
            // tint in code as named colors (in Storyboard) are not supported pre iOS 11
            opensInBrowserIndicator.tintColor = UIColor.applicationColor(Primary)
            opensInBrowserIndicator.isHidden = false
        } else {
            opensInBrowserIndicator.isHidden = true
        }
    }
}


@objc class RiistaMoreViewController: RiistaPageViewController, RiistaPageDelegate,
                                      UITableViewDelegate, UITableViewDataSource {

    // indicate nullability as tableView is referenced from refreshTabItem which can be
    // called before tableView is initialized
    @IBOutlet weak var tableView: UITableView?

    private var moreItems = [MoreItem]()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        refreshTabItem()
    }

    override func viewDidLoad() {
        if let tableView = self.tableView {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableHeaderView = UIView()
            tableView.tableFooterView = UIView()
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 60
        }

        initializeMoreItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        determineHuntingDirectorItemVisibility()
        pageSelected()
    }

    private func initializeMoreItems() {
        moreItems.append(MoreItem(.myDetails, iconResource: "more_person", titleResource: "MyDetails"))
        moreItems.append(MoreItem(.gallery, iconResource: "more_gallery", titleResource: "Gallery"))
        moreItems.append(MoreItem(.contactDetails, iconResource: "more_contacts", titleResource: "MenuContactDetails"))
        moreItems.append(MoreItem(.settings, iconResource: "more_settings", titleResource: "MenuSettings"))
        moreItems.append(MoreItem(.eventSearch, iconResource: "more_search", titleResource: "MenuEventSearch", opensInBrowser: true))
        moreItems.append(MoreItem(.magazine, iconResource: "more_magazine", titleResource: "MenuReadMagazine", opensInBrowser: true))
        moreItems.append(MoreItem(.seasons, iconResource: "more_seasons", titleResource: "MenuOpenSeasons", opensInBrowser: true))
        moreItems.append(MoreItem(.logout, iconResource: "more_logout", titleResource: "Logout"))

        updateShootingTestsItemVisibility()
        updateHuntingDirectorItemVisibility(animateVisibilityChange: false)
    }

    private func updateShootingTestsItemVisibility() {
        updateItemVisibility(
            item: MoreItem(.shootingTests, iconResource: "more_shooting", titleResource: "MenuShootingTests"),
            visible: RiistaSettings.userInfo()?.isShootingTestOfficial() == true,
            beforeItemOfType: .eventSearch,
            animateVisibilityChange: false
        )
    }

    private func updateHuntingDirectorItemVisibility(animateVisibilityChange: Bool) {
        updateItemVisibility(
            item: MoreItem(.huntingDirector, iconResource: "more_hunting_director", titleResource: "MenuHuntingDirector"),
            visible: UserSession.shared().groupHuntingAvailable,
            beforeItemOfType: .eventSearch,
            animateVisibilityChange: animateVisibilityChange
        )
    }

    private func updateItemVisibility(item: MoreItem, visible: Bool, beforeItemOfType: MoreItemType, animateVisibilityChange: Bool) {
        let currentIndex = indexOfItemWithType(item.type)

        if (visible && currentIndex == nil) {
            // intentionally fallback to end of the list if not found
            let targetIndex = indexOfItemWithType(beforeItemOfType) ?? moreItems.endIndex
            moreItems.insert(item, at: targetIndex)

            if (animateVisibilityChange) {
                tableView?.insertRows(at: [IndexPath(row: targetIndex, section: 0)], with: .automatic)
            }
        } else if (!visible && currentIndex != nil) {
            moreItems.remove(at: currentIndex!)

            if (animateVisibilityChange) {
                tableView?.deleteRows(at: [IndexPath(row: currentIndex!, section: 0)], with: .automatic)
            }
        }
    }

    private func determineHuntingDirectorItemVisibility() {
        UserSession.shared().checkHuntingDirectoryAvailability { [weak self] in
            guard let self = self else { return }
            self.updateHuntingDirectorItemVisibility(animateVisibilityChange: true)
        }
    }

    private func indexOfItemWithType(_ itemType: MoreItemType) -> Int? {
        return moreItems.firstIndex(where: { $0.type == itemType })
    }

    func pageSelected() {
        if let navController = navigationController as? RiistaNavigationController {
            navController.setLeftBarItem(nil)
            navController.setRightBarItems(nil)
        }
        
        navigationController?.title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MenuMore")
    }

    override func refreshTabItem() {
        self.tabBarItem.title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MenuMore")
        tableView?.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return moreItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "moreItemCell") as? MoreItemCell
        if (cell == nil) {
            cell = MoreItemCell(style: UITableViewCell.CellStyle.default,
                                 reuseIdentifier: "moreItemCell")
        }

        cell?.setup(item: moreItems[indexPath.row])
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = moreItems[indexPath.row]
        onItemClicked(item)
    }

    private func onItemClicked(_ item: MoreItem) {
        switch item.type {
        case .myDetails:
            launchViewController(identifier: "MyDetailsController")
            break
        case .gallery:
            launchViewController(identifier: "GalleryController")
            break
        case .contactDetails:
            launchViewController(identifier: "ContactDetailsController")
            break
        case .settings:
            launchViewController(identifier: "SettingsController")
            break
        case .shootingTests:
            launchViewController(identifier: "ShootingTestCalendarEventsController")
            break
        case .huntingDirector:
            launchViewController(controller: GroupHuntingLandingPageViewController())
            break
        case .eventSearch:
            launchEventSearch()
            break
        case .magazine:
            launchMagazineController()
            break
        case .seasons:
            launchHuntingSeasons()
            break
        case .logout:
            askLogoutConfirmation()
            break
        }
    }

    private func launchViewController(identifier: String) {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: identifier) {
            launchViewController(controller: controller)
        }
    }

    private func launchViewController(controller: UIViewController) {
        navigationController?.pushViewController(controller, animated: true)
    }

    private func launchEventSearch() {
        if let url = URL(string: RiistaBridgingUtils.RiistaLocalizedString(forkey: "UrlEventSearch")) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func launchMagazineController() {
        // don't use UIDevice.current.userInterfaceIdiom as it doesn't seem to give correct answers
        // since app is not universal. Instead detect type from model
        let runningOnIPad = UIDevice.current.model.localizedCaseInsensitiveContains("iPad")

        if (runningOnIPad) {
            if let url = URL(string: RiistaBridgingUtils.RiistaLocalizedString(forkey: "UrlMagazine")) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else {
            if let controller = self.storyboard?.instantiateViewController(withIdentifier: "MagazineController") as? RiistaMagazineViewController {
                controller.urlAddress = RiistaBridgingUtils.RiistaLocalizedString(forkey: "UrlMagazine")
                navigationController?.pushViewController(controller, animated: true)
            }
        }
    }

    private func launchHuntingSeasons() {
        if let url = URL(string: RiistaBridgingUtils.RiistaLocalizedString(forkey: "UrlHuntingSeasons")) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func askLogoutConfirmation() {
        let logoutController = MDCAlertController(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "Logout") + "?",
            message: nil
        )

        let cancelAction = MDCAlertAction(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "CancelRemove"),
            handler: nil
        )

        let okAction = MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK")) { _ in
            self.logout()
        }

        logoutController.addAction(cancelAction)
        logoutController.addAction(okAction)

        self.navigationController?.present(logoutController, animated: true, completion: nil)
    }

    private func logout() {
        guard let tabController = self.tabBarController as? RiistaTabBarViewController else {
            return
        }

        tabController.logout()
    }

}
