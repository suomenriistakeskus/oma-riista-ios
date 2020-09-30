import Foundation

/**
 A helper for objective c to allow instantiation and usage of
 ManagedContextRelatedObjectHolder<NSFetchedResultsController<DiaryEntry>>
 */
@objc class HarvestControllerHolder: NSObject {

    let delegateHolder: ManagedContextRelatedObjectHolder<NSFetchedResultsController<DiaryEntry>>

    override init() {
        delegateHolder = ManagedContextRelatedObjectHolder(objectProvider: {
            LogItemService.shared().setupHarvestResultsController()
        })
    }

    @objc func getObject() -> NSFetchedResultsController<DiaryEntry> {
        return delegateHolder.getObject()
    }
}
