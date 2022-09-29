import Foundation

protocol LogDelegate {
    func refresh()
}

class LogItemService: NSObject {

    private let predicateDefaultFormat = "pendingOperation != %d AND pointOfTime >= %@ AND pointOfTime < %@"
    private let predicateSpeciesFormat = "pendingOperation != %d AND pointOfTime >= %@ AND pointOfTime < %@ AND gameSpeciesCode IN %@"
    private let predicateWithImageFormat = "pendingOperation != %d AND pointOfTime >= %@ AND pointOfTime < %@ AND diaryImages.@count > 0"
    private let predicateSpeciesWithImageFormat = "pendingOperation != %d AND pointOfTime >= %@ AND pointOfTime < %@ AND gameSpeciesCode IN %@ AND diaryImages.@count > 0"


    private(set) var selectedLogType: RiistaEntryType = RiistaEntryTypeHarvest {
        didSet {
            selectedLogTypeUpdateTimeStamp = Date()
        }
    }

    /**
     * Time when selectedLogType was updated last time.
     */
    private(set) var selectedLogTypeUpdateTimeStamp: Date = Date()

    private(set) var selectedSeasonStart: Int = DatetimeUtil.huntingYearContaining(date: Date())

    private(set) var selectedSpecies = [Int]()
    private(set) var selectedCategory: Int?

    var logDelegate: LogDelegate?

    private static var sharedLogItemService: LogItemService = {
        let logItemService = LogItemService()

        return logItemService
    }()

    let _batch_size = 20

    private override init() {
    }

    class func shared() -> LogItemService {
        return sharedLogItemService
    }

    func setItemType(type: RiistaEntryType, forceUpdate: Bool = false) {
        if (type != selectedLogType || forceUpdate) {
            selectedLogType = type

            refreshItems()
        }
    }

    func setSeasonStartYear(year: Int) {
        if (year != selectedSeasonStart) {
            selectedSeasonStart = year

            refreshItems()
        }
    }

//    func setSrvaCalendarYear(year: Int) {
//        if (year != selectedSeasonStart) {
//            selectedSeasonStart = year
//
//            refreshItems()
//        }
//    }

    func setSpeciesList(speciesCodes: [Int]) {
        selectedSpecies = speciesCodes

        refreshItems()
    }

    func setSpeciesCategory(categoryCode: Int?) {
        selectedCategory = categoryCode
    }

    func setSpeciesCategory(categoryCode: Int) {
        selectedCategory = categoryCode
    }

    func clearSpeciesCategory() {
        setSpeciesCategory(categoryCode: nil)
    }

    private func refreshItems() {
        logDelegate?.refresh()
    }

    func setupHarvestResultsController(onlyWithImages: Bool = false) -> NSFetchedResultsController<DiaryEntry> {
        let appDelegate = UIApplication.shared.delegate as! RiistaAppDelegate
        let managedContext = appDelegate.managedObjectContext

        let fetchRequest = NSFetchRequest<DiaryEntry>(entityName: "DiaryEntry")

        let sortDescriptor = NSSortDescriptor(key: "pointOfTime", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let predicate = NSPredicate(format: onlyWithImages ? predicateWithImageFormat : predicateDefaultFormat,
                                    DiaryEntryOperationDelete,
                                    DatetimeUtil.seasonStartFor(startYear: selectedSeasonStart),
                                    DatetimeUtil.seasonEndFor(startYear: selectedSeasonStart))
        fetchRequest.predicate = predicate
        fetchRequest.fetchBatchSize = self._batch_size

        let fetchedResultsController = NSFetchedResultsController<DiaryEntry>(fetchRequest: fetchRequest,
                                                                              managedObjectContext: managedContext!,
                                                                              sectionNameKeyPath: "yearMonth",
                                                                              cacheName: "Root")

        return fetchedResultsController
    }

    func setupObservationResultsController(onlyWithImages: Bool = false) -> NSFetchedResultsController<ObservationEntry> {
        let appDelegate = UIApplication.shared.delegate as! RiistaAppDelegate
        let managedContext = appDelegate.managedObjectContext

        let fetchRequest = NSFetchRequest<ObservationEntry>(entityName: "ObservationEntry")

        let sortDescriptor = NSSortDescriptor(key: "pointOfTime", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let predicate = NSPredicate(format: onlyWithImages ? predicateWithImageFormat : predicateDefaultFormat,
                                    DiaryEntryOperationDelete,
                                    DatetimeUtil.seasonStartFor(startYear: selectedSeasonStart),
                                    DatetimeUtil.seasonEndFor(startYear: selectedSeasonStart))
        fetchRequest.predicate = predicate
        fetchRequest.fetchBatchSize = self._batch_size

        let fetchedResultsController = NSFetchedResultsController<ObservationEntry>(fetchRequest: fetchRequest,
                                                                                    managedObjectContext: managedContext!,
                                                                                    sectionNameKeyPath: "yearMonth",
                                                                                    cacheName: "Root")

        return fetchedResultsController
    }

    func setupSrvaResultsController(onlyWithImages: Bool = false) -> NSFetchedResultsController<SrvaEntry> {
        let appDelegate = UIApplication.shared.delegate as! RiistaAppDelegate
        let managedContext = appDelegate.managedObjectContext

        let fetchRequest = NSFetchRequest<SrvaEntry>(entityName: "SrvaEntry")

        let sortDescriptor = NSSortDescriptor(key: "pointOfTime", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let predicate = NSPredicate(format: onlyWithImages ? predicateWithImageFormat : predicateDefaultFormat,
                                    DiaryEntryOperationDelete,
                                    DatetimeUtil.yearStartFor(year: selectedSeasonStart),
                                    DatetimeUtil.yearEndFor(year: selectedSeasonStart))
        fetchRequest.predicate = predicate
        fetchRequest.fetchBatchSize = self._batch_size

        let fetchedResultsController = NSFetchedResultsController<SrvaEntry>(fetchRequest: fetchRequest,
                                                                              managedObjectContext: managedContext!,
                                                                              sectionNameKeyPath: "yearMonth",
                                                                              cacheName: "Root")

        return fetchedResultsController
    }

    func setupHarvestPredicate(onlyWithImage: Bool = false) -> NSPredicate {
        var predicate: NSPredicate

        if (selectedSpecies.count > 0) {
            predicate = NSPredicate(format: onlyWithImage ? predicateSpeciesWithImageFormat : predicateSpeciesFormat,
                                    DiaryEntryOperationDelete,
                                    DatetimeUtil.seasonStartFor(startYear: selectedSeasonStart),
                                    DatetimeUtil.seasonEndFor(startYear: selectedSeasonStart),
                                    selectedSpecies)
        }
        else {
            predicate = NSPredicate(format: onlyWithImage ? predicateWithImageFormat : predicateDefaultFormat,
                                    DiaryEntryOperationDelete,
                                    DatetimeUtil.seasonStartFor(startYear: selectedSeasonStart),
                                    DatetimeUtil.seasonEndFor(startYear: selectedSeasonStart))
        }

        return predicate
    }


    func setupObservationPredicate(onlyWithImage: Bool = false) -> NSPredicate {
        var predicate: NSPredicate

        if (selectedSpecies.count > 0) {
            predicate = NSPredicate(format: onlyWithImage ? predicateSpeciesWithImageFormat : predicateSpeciesFormat,
                                    DiaryEntryOperationDelete,
                                    DatetimeUtil.seasonStartFor(startYear: selectedSeasonStart),
                                    DatetimeUtil.seasonEndFor(startYear: selectedSeasonStart),
                                    selectedSpecies)
        }
        else {
            predicate = NSPredicate(format: onlyWithImage ? predicateWithImageFormat : predicateDefaultFormat,
                                    DiaryEntryOperationDelete,
                                    DatetimeUtil.seasonStartFor(startYear: selectedSeasonStart),
                                    DatetimeUtil.seasonEndFor(startYear: selectedSeasonStart))
        }

        return predicate
    }

    func setupSrvaPredicate(onlyWithImage: Bool = false) -> NSPredicate {
        var predicate: NSPredicate

        if (selectedSpecies.count > 0) {
            predicate = NSPredicate(format: onlyWithImage ? predicateSpeciesWithImageFormat : predicateSpeciesFormat,
                                    DiaryEntryOperationDelete,
                                    DatetimeUtil.yearStartFor(year: selectedSeasonStart),
                                    DatetimeUtil.yearEndFor(year: selectedSeasonStart),
                                    selectedSpecies)
        }
        else {
            predicate = NSPredicate(format: onlyWithImage ? predicateWithImageFormat : predicateDefaultFormat,
                                    DiaryEntryOperationDelete,
                                    DatetimeUtil.yearStartFor(year: selectedSeasonStart),
                                    DatetimeUtil.yearEndFor(year: selectedSeasonStart))
        }

        return predicate
    }
}
