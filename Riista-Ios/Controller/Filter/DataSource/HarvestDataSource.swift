import Foundation
import RiistaCommon

class HarvestDataSource: ManagedObjectContextDataSource<DiaryEntry> {
    let onlyEntitiesWithImages: Bool

    private var seasonStartFilter: Int = Int(Date().toLocalDate().getHuntingYear())
    private var speciesFilter: [RiistaCommon.Species] = []

    init(onlyEntitiesWithImages: Bool) {
        self.onlyEntitiesWithImages = onlyEntitiesWithImages
        super.init(
            filteredEntityType: .harvest,
            entitySpeciesCodeAccessor: { $0.gameSpeciesCode?.intValue },
            entityAmountAccessor: { $0.amount?.intValue }
        )
    }

    override func getPossibleSeasonsOrYears(_ onCompleted: @escaping ([Int]?) -> Void) {
        let seasons = RiistaGameDatabase.sharedInstance()?.eventYears(DiaryEntryTypeHarvest)
            .compactMap { eventYear in
                (eventYear as? NSNumber)?.intValue
            } ?? []

        onCompleted(seasons)
    }

    override func onFilterChanged(newFilter: EntityFilter, oldFilter: EntityFilter?) -> Bool {
        guard let newFilter = newFilter as? HarvestFilter else {
            fatalError("Only supporting HarvestFilter for HarvestDataSource")
        }

        if (newFilter.seasonStartYear != seasonStartFilter || newFilter.species != speciesFilter) {
            resultController.fetchRequest.predicate = createPredicate(
                seasonStartYear: newFilter.seasonStartYear,
                species: newFilter.species
            )

            return true
        }

        return false
    }

    override func getSectionName(sectionIndex: Int) -> String? {
        guard let entity: DiaryEntry = getEntityFromSection(sectionIndex: sectionIndex, entityIndex: 0) else {
            print("Failed to get section name. Couldn't obtain first entity in section")
            return nil
        }

        return MonthNameFormatter.formatMonthName(date: entity.pointOfTime)
    }

    override func setupController() -> NSFetchedResultsController<DiaryEntry> {
        let appDelegate = UIApplication.shared.delegate as! RiistaAppDelegate
        let managedContext = appDelegate.managedObjectContext

        let fetchRequest = NSFetchRequest<DiaryEntry>(entityName: "DiaryEntry")

        let sortDescriptor = NSSortDescriptor(key: "pointOfTime", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        fetchRequest.predicate = createPredicate(seasonStartYear: seasonStartFilter, species: speciesFilter)
        fetchRequest.fetchBatchSize = 20

        let fetchedResultsController = NSFetchedResultsController<DiaryEntry>(
            fetchRequest: fetchRequest,
            managedObjectContext: managedContext!,
            sectionNameKeyPath: "yearMonth",
            cacheName: "Root"
        )

        return fetchedResultsController
    }

    func createPredicate(seasonStartYear: Int, species: [RiistaCommon.Species]) -> NSPredicate {
        var predicate: NSPredicate

        if (species.count > 0) {
            let speciesCodes = species.compactMap { species in
                species.knownSpeciesCodeOrNull()?.intValue
            }

            predicate = NSPredicate(
                format: onlyEntitiesWithImages ? predicateSpeciesWithImageFormat : predicateSpeciesFormat,
                DiaryEntryOperationDelete,
                DatetimeUtil.seasonStartFor(startYear: seasonStartYear),
                DatetimeUtil.seasonEndFor(startYear: seasonStartYear),
                speciesCodes
            )
        }
        else {
            predicate = NSPredicate(
                format: onlyEntitiesWithImages ? predicateWithImageFormat : predicateDefaultFormat,
                DiaryEntryOperationDelete,
                DatetimeUtil.seasonStartFor(startYear: seasonStartYear),
                DatetimeUtil.seasonEndFor(startYear: seasonStartYear)
            )
        }

        self.seasonStartFilter = seasonStartYear
        self.speciesFilter = species

        return predicate
    }
}

