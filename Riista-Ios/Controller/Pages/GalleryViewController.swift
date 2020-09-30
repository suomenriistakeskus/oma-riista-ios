import Foundation

import MaterialComponents

class GalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, RiistaPageDelegate, LogFilterDelegate, LogDelegate
{

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterView: LogFilterView!

    lazy var harvestResultsController = logItemService.setupHarvestResultsController(onlyWithImages: true)

    lazy var observationResultsController = logItemService.setupObservationResultsController(onlyWithImages: true)

    lazy var srvaResultsController = logItemService.setupSrvaResultsController(onlyWithImages: true)

    var logItemService: LogItemService

    required init?(coder: NSCoder) {
        logItemService = LogItemService.shared()

        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self

        filterView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.pageSelected()

        let navController = self.navigationController as? RiistaNavigationController
        navController?.changeTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "Gallery"))

        logItemService.logDelegate = self

        filterView.updateTexts()
        filterView.logType = logItemService.selectedLogType
        filterView.seasonStartYear = logItemService.selectedSeasonStart

        filterView.refreshFilteredSpecies(selectedCategory: logItemService.selectedCategory ?? -1,
                                          selectedSpecies: logItemService.selectedSpecies)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let horizontalSpacing: CGFloat = flowLayout.minimumInteritemSpacing + flowLayout.sectionInset.left + flowLayout.sectionInset.right

            let width: CGFloat = (self.collectionView.frame.size.width - horizontalSpacing) / 2.0
            flowLayout.itemSize = CGSize(width: width, height: width + 49)
        }

        refreshData()
    }

    func refreshData() {
        do {
            switch logItemService.selectedLogType {
            case RiistaEntryTypeHarvest:
                harvestResultsController.fetchRequest.predicate = logItemService.setupHarvestPredicate(onlyWithImage: true)
                try harvestResultsController.performFetch()
            case RiistaEntryTypeObservation:
                observationResultsController.fetchRequest.predicate = logItemService.setupObservationPredicate(onlyWithImage: true)
                try observationResultsController.performFetch()
            case RiistaEntryTypeSrva:
                srvaResultsController.fetchRequest.predicate = logItemService.setupSrvaPredicate(onlyWithImage: true)
                try srvaResultsController.performFetch()
            default:
                break
            }

            self.collectionView.reloadData()
        } catch {
            NSLog("Failed to performFetch")
        }
    }

    // MARK: - RiistaPageDelegate

    func pageSelected() {
        let navController = self.navigationController as! RiistaNavigationController;

        navController.setLeftBarItem(nil)
        navController.setRightBarItems(nil)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch logItemService.selectedLogType {
        case RiistaEntryTypeHarvest:
            return harvestResultsController.fetchedObjects?.count ?? 0
        case RiistaEntryTypeObservation:
            return observationResultsController.fetchedObjects?.count ?? 0
        case RiistaEntryTypeSrva:
            return srvaResultsController.fetchedObjects?.count ?? 0
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryItemCell", for: indexPath) as! GalleryItemCell

        switch logItemService.selectedLogType {
        case RiistaEntryTypeHarvest:
            let item = harvestResultsController.fetchedObjects![indexPath.row] as DiaryEntry

            _ = cell.setupFrom(diaryEntry: item, parent: self)
        case RiistaEntryTypeObservation:
            let item = observationResultsController.fetchedObjects![indexPath.row] as ObservationEntry

            _ = cell.setupFrom(observation: item, parent: self)
        case RiistaEntryTypeSrva:
            let item = srvaResultsController.fetchedObjects![indexPath.row] as SrvaEntry

            _ = cell.setupFrom(srva: item, parent: self)
        default:
            break
        }

        return cell
    }

    // Mark: - LogDelegate

    func refresh() {
        refreshData()
        collectionView.reloadData()
    }

    // Mark: - LogFilterDelegate

    func onFilterTypeSelected(type: RiistaEntryType) {
        logItemService.setItemType(type: type)

        filterView.seasonStartYear = logItemService.selectedSeasonStart
    }

    func onFilterSeasonSelected(seasonStartYear: Int) {
        logItemService.setSeasonStartYear(year: seasonStartYear)
    }

    func onFilterSpeciesSelected(speciesCodes: [Int]) {
        filterView.setSelectedSpecies(speciesCodes: speciesCodes)

        logItemService.setSpeciesCategory(categoryCode: nil)
        logItemService.setSpeciesList(speciesCodes: speciesCodes)
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
    }

    func presentSpeciesSelect() {
        filterView.presentSpeciesSelect(navigationController: navigationController!, delegate: self)
    }
}
