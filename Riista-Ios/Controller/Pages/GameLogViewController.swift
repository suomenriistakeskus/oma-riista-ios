import Foundation

class GameLogViewController: RiistaPageViewController, UITableViewDataSource, UITableViewDelegate, RiistaPageDelegate, LogFilterDelegate, LogDelegate {

    @IBOutlet weak var filterView: LogFilterView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var seasonStatsView: SeasonStatsView!

    lazy var harvestResultsControllerHolder = (ManagedContextRelatedObjectHolder<NSFetchedResultsController<DiaryEntry>>(
        objectProvider: { return (self.logItemService.setupHarvestResultsController()) })
    )

    lazy var observationResultsControllerHolder = (ManagedContextRelatedObjectHolder<NSFetchedResultsController<ObservationEntry>>(
        objectProvider: { return (self.logItemService.setupObservationResultsController()) })
    )

    lazy var srvaResultsControllerHolder = (ManagedContextRelatedObjectHolder<NSFetchedResultsController<SrvaEntry>>(
        objectProvider: { return (self.logItemService.setupSrvaResultsController()) })
    )

    var logItemService: LogItemService

    let _batch_size = 20

    static let monthNameFormatter = { () -> DateFormatter in
        let dateFormatter = DateFormatter()
        dateFormatter.locale = RiistaUtils.appLocale()
        dateFormatter.dateFormat = "LLLL"

        return dateFormatter
    }()

    required init?(coder: NSCoder) {
        logItemService = LogItemService.shared()

        super.init(coder: coder)

        refreshTabItem()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        filterView.delegate = self

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onCalendarEntriesUpdated),
                                               name: NSNotification.Name(rawValue: RiistaCalendarEntriesUpdatedKey),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onLanguageChanged),
                                               name: NSNotification.Name(rawValue: RiistaLanguageSelectionUpdatedKey),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onUserInfoUpdated),
                                               name: NSNotification.Name(rawValue: RiistaUserInfoUpdatedKey),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onLogTypeSelected),
                                               name: NSNotification.Name(rawValue: RiistaLogTypeSelectedKey),
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        pageSelected()

        logItemService.logDelegate = self

        filterView.updateTexts()
        filterView.logType = logItemService.selectedLogType
        filterView.seasonStartYear = logItemService.selectedSeasonStart

        filterView.refreshFilteredSpecies(selectedCategory: logItemService.selectedCategory ?? -1,
                                          selectedSpecies: logItemService.selectedSpecies)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshAfterManagedObjectContextChange),
                                               name: NSNotification.Name.ManagedObjectContextChanged,
                                               object: nil)

        refreshMonthNameFormatterLocale()
        refreshData()
        filterView.setupUserRelatedData()
    }

    func getHarvestResultController() -> NSFetchedResultsController<DiaryEntry> {
        return harvestResultsControllerHolder.getObject()
    }

    func getObservationResultController() -> NSFetchedResultsController<ObservationEntry> {
        return observationResultsControllerHolder.getObject()
    }

    func getSrvaResultController() -> NSFetchedResultsController<SrvaEntry> {
        return srvaResultsControllerHolder.getObject()
    }

    func refreshMonthNameFormatterLocale() {
        GameLogViewController.monthNameFormatter.locale = RiistaUtils.appLocale()
    }

    func refreshData() {
        do {
            switch logItemService.selectedLogType {
            case RiistaEntryTypeHarvest:
                let stats = RiistaGameDatabase.sharedInstance()?.stats(forHarvestSeason: logItemService.selectedSeasonStart)
                seasonStatsView.refreshStats(stats: stats ?? SeasonStats.empty())

                getHarvestResultController().fetchRequest.predicate = logItemService.setupHarvestPredicate()
                try getHarvestResultController().performFetch()
            case RiistaEntryTypeObservation:
                let stats = RiistaGameDatabase.sharedInstance()?.stats(forObservationSeason: logItemService.selectedSeasonStart)
                seasonStatsView.refreshStats(stats: stats ?? SeasonStats.empty())

                getObservationResultController().fetchRequest.predicate = logItemService.setupObservationPredicate()
                try getObservationResultController().performFetch()
            case RiistaEntryTypeSrva:
                let stats = RiistaGameDatabase.sharedInstance()?.stats(forSrvaYear: logItemService.selectedSeasonStart)
                seasonStatsView.refreshStats(stats: stats ?? SeasonStats.empty())

                getSrvaResultController().fetchRequest.predicate = logItemService.setupSrvaPredicate()
                try getSrvaResultController().performFetch()
            default:
                break
            }

            updateStatsVisibility()
            tableView.reloadData()
        } catch {
            NSLog("Failed to performFetch")
        }
    }

    func updateStatsVisibility() {
        let selectedType = logItemService.selectedLogType
        let selectedSpeciesCodes = logItemService.selectedSpecies

        let hideStats = RiistaEntryTypeSrva == selectedType || selectedSpeciesCodes.count > 0

        seasonStatsView.isHidden = hideStats
        seasonStatsView.frame.size.height = hideStats ? 0.0 : seasonStatsView.intrinsicContentHeight
        seasonStatsView.layoutIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // stats view contains labels that are possibly wrapped to second line. Whether label gets wrapped or not
        // is not known before label is layouted for the first time. Since the total height of the stats view
        // depends on whether labels are wrapped or not we need to update the height after subviews have been layouted
        updateStatsVisibility()
    }

    override func refreshTabItem() {
        self.tabBarItem.title = "MenuGameLog".localized()
    }

    // Mark: - Notification handlers

    @objc func refreshAfterManagedObjectContextChange() {
        refreshData()
        filterView.setupUserRelatedData()
    }

    @objc func onCalendarEntriesUpdated() {
        NSLog("onCalendarEntriesUpdated")
    }

    @objc func onLanguageChanged() {
        NSLog("onLanguageChanged")
    }

    @objc func onUserInfoUpdated() {
        NSLog("onUserInfoUpdated")
    }

    @objc func onLogTypeSelected(notification: Notification) {
        if let rawEntryTypeValue = (notification.object as? NSNumber)?.uint32Value {
            switch rawEntryTypeValue {
            case RiistaEntryTypeHarvest.rawValue:
                logItemService.setItemType(type: RiistaEntryTypeHarvest)
            case RiistaEntryTypeObservation.rawValue:
                logItemService.setItemType(type: RiistaEntryTypeObservation)
            case RiistaEntryTypeSrva.rawValue:
                logItemService.setItemType(type: RiistaEntryTypeSrva)
            default:
                print("Unknown log type selected")
            }
        }
    }


    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        switch logItemService.selectedLogType {
        case RiistaEntryTypeHarvest:
            return getHarvestResultController().sections?.count ?? 0
        case RiistaEntryTypeObservation:
            return getObservationResultController().sections?.count ?? 0
        case RiistaEntryTypeSrva:
            return getSrvaResultController().sections?.count ?? 0
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch logItemService.selectedLogType {
        case RiistaEntryTypeHarvest:
            let sectionContent = getHarvestResultController().sections![section]
            return sectionContent.numberOfObjects
        case RiistaEntryTypeObservation:
            let sectionContent = getObservationResultController().sections![section]
            return sectionContent.numberOfObjects
        case RiistaEntryTypeSrva:
            let sectionContent = getSrvaResultController().sections![section]
            return sectionContent.numberOfObjects
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCell(withIdentifier: "GameLogHeaderCell") as! GameLogHeaderCell
        header.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: header.frame.size.height)

        switch logItemService.selectedLogType {
        case RiistaEntryTypeHarvest:
            let sectionContent = getHarvestResultController().sections![section]
            let harvest = sectionContent.objects?.first as! DiaryEntry

            header.monthLabel.text = GameLogViewController.monthNameFormatter.string(from: harvest.pointOfTime)
        case RiistaEntryTypeObservation:
            let sectionContent = getObservationResultController().sections![section]
            let observation = sectionContent.objects?.first as! ObservationEntry

            header.monthLabel.text = GameLogViewController.monthNameFormatter.string(from: observation.pointOfTime!)
        case RiistaEntryTypeSrva:
            let sectionContent = getSrvaResultController().sections![section]
            let srva = sectionContent.objects?.first as! SrvaEntry

            header.monthLabel.text = GameLogViewController.monthNameFormatter.string(from: srva.pointOfTime!)
        default:
            header.monthLabel.text = "-"
        }

        header.timeLine.isHidden = section == 0

        return header
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameLogItemCell") as? GameLogItemCell
        cell?.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: (cell?.frame.size.height)!)

        switch logItemService.selectedLogType {
        case RiistaEntryTypeHarvest:
            let item = getHarvestResultController().object(at: indexPath)
            cell?.setupFromHarvest(harvest: item,
                                   isFirst: (indexPath.section == 0 && indexPath.row == 0),
                                   isLast: indexPath.section == tableView.numberOfSections - 1 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1)
        case RiistaEntryTypeObservation:
            let item = getObservationResultController().object(at: indexPath)
            cell?.setupFromObservation(observation: item,
                                       isFirst: (indexPath.section == 0 && indexPath.row == 0),
                                       isLast: indexPath.section == tableView.numberOfSections - 1 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1)
        case RiistaEntryTypeSrva:
            let item = getSrvaResultController().object(at: indexPath)
            cell?.setupFromSrva(srva: item,
                                isFirst: (indexPath.section == 0 && indexPath.row == 0),
                                isLast: indexPath.section == tableView.numberOfSections - 1 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1)
        default:
            break
        }

        return cell!

    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch logItemService.selectedLogType {
        case RiistaEntryTypeHarvest:
            let sb = UIStoryboard(name: "HarvestStoryboard", bundle: nil)
            let dest = sb.instantiateInitialViewController() as? RiistaLogGameViewController
            dest?.eventId = getHarvestResultController().object(at: indexPath).objectID

            let segue = UIStoryboardSegue(identifier: "", source: self, destination: dest!, performHandler: {
                self.navigationController?.pushViewController(dest!, animated: true)
            })
            segue.perform()
        case RiistaEntryTypeObservation:
            let delegate = UIApplication.shared.delegate as! RiistaAppDelegate
            let context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
            context.parent = delegate.managedObjectContext
            let objectId = getObservationResultController().object(at: indexPath).objectID

            let observationEntry = RiistaGameDatabase.sharedInstance().observationEntry(with: objectId, context: context)
            if let observation = observationEntry?.toCommonObservation(objectId: objectId) {
                let viewController = ViewObservationViewController(observation: observation)
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        case RiistaEntryTypeSrva:
            let delegate = UIApplication.shared.delegate as! RiistaAppDelegate
            let context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
            context.parent = delegate.managedObjectContext
            let objectId = getSrvaResultController().object(at: indexPath).objectID

            let srvaEntry = RiistaGameDatabase.sharedInstance().srvaEntry(with: objectId, context: context)
            if let srvaEvent = srvaEntry?.toSrvaEvent(objectId: objectId) {
                let viewSrvaViewController = ViewSrvaEventViewController(srvaEvent: srvaEvent)
                self.navigationController?.pushViewController(viewSrvaViewController, animated: true)
            }
        default:
            break
        }
    }

    // MARK: - RiistaPageDelegate

    func pageSelected() {
        self.navigationItem.title = "Gamelog".localized()

        let plusImage = UIImage(named: "add_white")
        let plusButton = UIBarButtonItem(image: plusImage, style: .plain, target: self, action: #selector(onCreateItemClick))

        self.navigationItem.rightBarButtonItem = plusButton
    }

    @objc func onCreateItemClick() {
        switch logItemService.selectedLogType {
        case RiistaEntryTypeHarvest:
            let sb = UIStoryboard(name: "HarvestStoryboard", bundle: nil)
            let dest = sb.instantiateInitialViewController() as? RiistaLogGameViewController

            let segue = UIStoryboardSegue(identifier: "", source: self, destination: dest!, performHandler: {
                self.navigationController?.pushViewController(dest!, animated: true)
            })
            segue.perform()
        case RiistaEntryTypeObservation:
            let controller = CreateObservationViewController(initialSpeciesCode: nil)
            self.navigationController?.pushViewController(controller, animated: true)
        default:
            let controller = CreateSrvaEventViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    // Mark: - LogDelegate

    func refresh() {
        refreshData()
        tableView.reloadData()
    }

    // Mark - LogFilterDelegate

    func onFilterTypeSelected(selectedType: LogFilterView.FilteredType, oldType: LogFilterView.FilteredType) {
        guard let type = selectedType.toRiistaEntryType() else { return }

        logItemService.setItemType(type: type)
        filterView.seasonStartYear = logItemService.selectedSeasonStart

        updateStatsVisibility()
    }

    func onFilterSeasonSelected(seasonStartYear: Int) {
        logItemService.setSeasonStartYear(year: seasonStartYear)
    }

    func onFilterSpeciesSelected(speciesCodes: [Int]) {
        filterView.setSelectedSpecies(speciesCodes: speciesCodes)

        logItemService.setSpeciesCategory(categoryCode: nil)
        logItemService.setSpeciesList(speciesCodes: speciesCodes)

        updateStatsVisibility()
    }

    func onFilterCategorySelected(categoryCode: Int) {
        filterView.setSelectedCategory(categoryCode: categoryCode)

        let species = RiistaGameDatabase.sharedInstance()?.speciesList(withCategoryId: categoryCode) as! [RiistaSpecies]
        var speciesCodes = [Int]()

        for item in species {
            speciesCodes.append(item.speciesId)
        }

        logItemService.setSpeciesCategory(categoryCode: categoryCode)
        logItemService.setSpeciesList(speciesCodes: speciesCodes)

        updateStatsVisibility()
    }

    func onFilterPointOfInterestListClicked() {
        // nop
    }

    func presentSpeciesSelect() {
        filterView.presentSpeciesSelect(navigationController: navigationController!, delegate: self)
    }
}
