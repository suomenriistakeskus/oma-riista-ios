import Foundation
import CoreData

class ManagedObjectContextDataSource<EntityType : NSManagedObject>: TypedFilterableEntityDataSource<EntityType> {
    let predicateDefaultFormat = "pendingOperation != %d AND pointOfTime >= %@ AND pointOfTime < %@"
    let predicateSpeciesFormat = "pendingOperation != %d AND pointOfTime >= %@ AND pointOfTime < %@ AND gameSpeciesCode IN %@"
    let predicateWithImageFormat = "pendingOperation != %d AND pointOfTime >= %@ AND pointOfTime < %@ AND diaryImages.@count > 0"
    let predicateSpeciesWithImageFormat = "pendingOperation != %d AND pointOfTime >= %@ AND pointOfTime < %@ AND gameSpeciesCode IN %@ AND diaryImages.@count > 0"

    private lazy var resultControllerHolder: ManagedContextRelatedObjectHolder<NSFetchedResultsController<EntityType>> = {
        ManagedContextRelatedObjectHolder<NSFetchedResultsController<EntityType>>(
            objectProvider: { self.setupController() }
        )
    }()

    var resultController: NSFetchedResultsController<EntityType> {
        resultControllerHolder.getObject()
    }

    let entitySpeciesCodeAccessor: (EntityType) -> Int?
    let entityAmountAccessor: (EntityType) -> Int?

    init(
        filteredEntityType: FilterableEntityType,
        entitySpeciesCodeAccessor: @escaping (EntityType) -> Int?,
        entityAmountAccessor: @escaping (EntityType) -> Int?
    ) {
        self.entitySpeciesCodeAccessor = entitySpeciesCodeAccessor
        self.entityAmountAccessor = entityAmountAccessor

        super.init(filteredEntityType: filteredEntityType)
    }

    override func fetchEntities() {
        try? resultController.performFetch()

        listener?.onDataSourceDataUpdated(for: filteredEntityType)
    }

    override func getSeasonStats() -> SeasonStats? {
        guard let entities = resultController.fetchedObjects else {
            return nil
        }

        let seasonStats = SeasonStats.empty()

        if (entities.isEmpty) {
            print("No entities, returning empty stats")
            return seasonStats
        }

        let gameDatabase = RiistaGameDatabase.sharedInstance()

        entities.forEach { entity in
            if let speciesCode = entitySpeciesCodeAccessor(entity),
               let species = gameDatabase?.species(byId: speciesCode) {
                seasonStats.increaseCategoryAmount(
                    categoryId: species.categoryId,
                    by: entityAmountAccessor(entity)
                )
            }
        }

        return seasonStats
    }

    open func setupController() -> NSFetchedResultsController<EntityType> {
        fatalError("Subclasses are expected to implement this")
    }

    override func getTotalEntityCount() -> Int {
        resultController.fetchedObjects?.count ?? 0
    }

    override func getEntities() -> [EntityType] {
        resultController.fetchedObjects ?? []
    }

    override func getEntity(index: Int) -> EntityType? {
        guard let entity = resultController.fetchedObjects?.getOrNil(index: index) else {
            print("Couldn't find an entity at index \(index)")
            return nil
        }

        return entity
    }

    override func getSectionCount() -> Int {
        resultController.sections?.count ?? 0
    }

    override func getSectionEntityCount(sectionIndex: Int) -> Int? {
        getSection(sectionIndex: sectionIndex)?.objects?.count
    }

    override func getEntity(indexPath: IndexPath) -> EntityType? {
        resultController.object(at: indexPath)
    }

    func getEntityFromSection(sectionIndex: Int, entityIndex: Int) -> EntityType? {
        getEntity(indexPath: IndexPath(row: entityIndex, section: sectionIndex))
    }

    func getSection(sectionIndex: Int) -> NSFetchedResultsSectionInfo? {
        resultController.sections?.getOrNil(index: sectionIndex)
    }
}

