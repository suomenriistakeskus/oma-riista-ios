import Foundation
import RiistaCommon

class GameLogViewController: RiistaPageViewController, RiistaPageDelegate, LogFilterViewDelegate,
                             GameLogDataSourceListener {

    @IBOutlet weak var filterView: LogFilterView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var seasonStatsView: SeasonStatsView!

    private lazy var gameLogDataSource: GameLogDataSource = {
        let dataSource = GameLogDataSource()
        dataSource.tableView = tableView
        dataSource.listener = self

        return dataSource
    }()

    private lazy var createNewEntryButton: HideableUIBarButtonItem = {
        let button = HideableUIBarButtonItem(
            image: UIImage(named: "add_white"),
            style: .plain,
            target: self,
            action: #selector(onCreateItemClick)
        )
        return button
    }()

    private lazy var synchronizeManuallyButton: HideableUIBarButtonItem = {
        let button = HideableUIBarButtonItem(
            image: UIImage(named: "refresh_white"),
            style: .plain,
            target: self,
            action: #selector(performManualAppSync)
        )
        return button
    }()

    private lazy var allNavBarButtons: [HideableUIBarButtonItem] = [synchronizeManuallyButton, createNewEntryButton]

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            self,
            action: #selector(performManualAppSync),
            for: .valueChanged
        )

        return refreshControl
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        refreshTabItem()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        refreshTabItem()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.refreshControl = refreshControl

        filterView.dataSource = gameLogDataSource
        filterView.delegate = self
        filterView.changeListener = SharedEntityFilterStateUpdater()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onCalendarEntriesUpdated),
            name: NSNotification.Name(rawValue: RiistaCalendarEntriesUpdatedKey),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshAfterManagedObjectContextChange),
            name: NSNotification.Name.ManagedObjectContextChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onManualSynchronizationPossibleStatusChanged(notification:)),
            name: Notification.Name.ManualSynchronizationPossibleStatusChanged,
            object: nil
        )
        // TODO: selecting correct entity type when new one is created
/*        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onLogTypeSelected),
                                               name: NSNotification.Name(rawValue: RiistaLogTypeSelectedKey),
                                               object: nil)*/
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        SharedEntityFilterState.shared.addListener(gameLogDataSource)
        filterView.updateTexts()

        updateManualSyncButton(
            manualSyncPossible: AppSync.shared.manualSynchronizationPossible,
            updateManualSyncButtonVisibility: true
        )

        self.navigationItem.title = "Gamelog".localized()
        self.navigationItem.rightBarButtonItems = allNavBarButtons.visibleButtons
    }

    override func viewWillDisappear(_ animated: Bool) {
        SharedEntityFilterState.shared.removeListener(gameLogDataSource)

        super.viewWillDisappear(animated)
    }

    private func refreshStats(updateValues: Bool) {
        let seasonStats: SeasonStats?
        if (updateValues) {
            seasonStats = gameLogDataSource.getSeasonStats()
        } else {
            seasonStats = nil
        }

        let hideStatsView: Bool
        if let dataSource = gameLogDataSource.activeDataSource,
           let filter = dataSource.filter, filter.entityType != .srva && !filter.hasSpeciesFilter {

            // stats are allowed to be displayed. Hide them if we don't have them even though we should!
            if let seasonStats = seasonStats, updateValues {
                hideStatsView = false
                seasonStatsView.refreshStats(stats: seasonStats)
            } else {
                if (updateValues) {
                    print("Should have seasons stats but for some reason don't, hiding stats")
                }
                hideStatsView = updateValues
            }
        } else {
            hideStatsView = true
        }

        seasonStatsView.isHidden = hideStatsView
        seasonStatsView.frame.size.height = hideStatsView ? 0.0 : seasonStatsView.intrinsicContentHeight
        seasonStatsView.layoutIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // stats view contains labels that are possibly wrapped to second line. Whether label gets wrapped or not
        // is not known before label is layouted for the first time. Since the total height of the stats view
        // depends on whether labels are wrapped or not we need to update the height after subviews have been layouted
        refreshStats(updateValues: false)
    }

    override func refreshTabItem() {
        self.tabBarItem.title = "MenuGameLog".localized()
    }

    @objc private func performManualAppSync() {
        AppSync.shared.synchronize(usingMode: .manual)
    }

    private func updateManualSyncPossible(manualSyncPossible: Bool) {
        updateManualSyncButton(manualSyncPossible: manualSyncPossible, updateManualSyncButtonVisibility: false)
        updateRefreshControl(manualSyncPossible: manualSyncPossible)
    }

    private func updateManualSyncButton(manualSyncPossible: Bool, updateManualSyncButtonVisibility: Bool) {
        if (updateManualSyncButtonVisibility) {
            // for some reason isHidden seems to be restored under the hood and thus it is not reliable.
            // -> use different property
            synchronizeManuallyButton.shouldBeHidden = AppSync.shared.isAutomaticSyncEnabled()
        }

        synchronizeManuallyButton.isEnabled = manualSyncPossible
    }

    private func updateRefreshControl(manualSyncPossible: Bool) {
        if (refreshControl.isRefreshing) {
            // manual sync started using refreshcontrol: don't remove, only end refreshing when needed
            if (manualSyncPossible) {
                refreshControl.endRefreshing()
            }
        } else {
            // sync started differently, prevent refreshcontrol while sync is running
            if (!manualSyncPossible) {
                tableView.refreshControl = nil
            } else {
                tableView.refreshControl = refreshControl
            }
        }
    }

    // MARK: GameLogDataSourceListener

    func onDataSourceDataUpdated(for entityType: FilterableEntityType) {
        refreshStats(updateValues: true)
        filterView.refresh()
    }

    func onHarvestClicked(harvest: DiaryEntry) {
        let delegate = UIApplication.shared.delegate as! RiistaAppDelegate
        let context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        context.parent = delegate.managedObjectContext
        let objectId = harvest.objectID

        let diaryEntry = RiistaGameDatabase.sharedInstance().diaryEntry(with: objectId, context: context)
        if let harvest = diaryEntry?.toCommonHarvest(objectId: objectId) {
            let viewController = ViewHarvestViewController(harvest: harvest)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    func onObservationClicked(observation: CommonObservation) {
        guard let observationId = observation.localId?.int64Value else {
            return
        }

        let viewController = ViewObservationViewController(observationId: observationId)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func onSrvaClicked(srva: CommonSrvaEvent) {
        guard let srvaEventId = srva.localId?.int64Value else {
            return
        }

        let viewController = ViewSrvaEventViewController(srvaEventId: srvaEventId)
        navigationController?.pushViewController(viewController, animated: true)
    }


    // MARK: - Notification handlers

    @objc private func refreshAfterManagedObjectContextChange() {
        gameLogDataSource.reloadContent()
    }

    @objc private func onCalendarEntriesUpdated() {
        // updated content is not necessarily displayed but let's refresh anyhow
        gameLogDataSource.reloadContent()
    }

    @objc private func onManualSynchronizationPossibleStatusChanged(notification: Notification) {
        guard let manualSyncPossible = (notification.object as? NSNumber)?.boolValue else {
            return
        }

        updateManualSyncPossible(manualSyncPossible: manualSyncPossible)
    }


    // MARK: - RiistaPageDelegate

    func pageSelected() {
        self.navigationItem.title = "Gamelog".localized()
    }

    @objc func onCreateItemClick() {
        guard let selectedEntityType = gameLogDataSource.activeDataSource?.filteredEntityType else {
            return
        }

        switch selectedEntityType {
        case .harvest:
            let controller = CreateHarvestViewController(initialSpeciesCode: nil)
            self.navigationController?.pushViewController(controller, animated: true)
        case .observation:
            let controller = CreateObservationViewController(initialSpeciesCode: nil)
            self.navigationController?.pushViewController(controller, animated: true)
        case .srva:
            let controller = CreateSrvaEventViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        case .pointOfInterest:
            print("Not supported: creating POIs")
            break
        }
    }


    // Mark - LogFilterViewDelegate

    func onFilterPointOfInterestListClicked() {
        // nop
    }

    func presentSpeciesSelect() {
        guard let navigationController = navigationController else { return }

        filterView.presentSpeciesSelect(navigationController: navigationController)
    }
}
