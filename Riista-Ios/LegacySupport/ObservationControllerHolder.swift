import Foundation

/**
 A helper for objective c to allow instantiation and usage of
 ManagedContextRelatedObjectHolder<NSFetchedResultsController<ObservationEntry>>
 */
@objc class ObservationControllerHolder: NSObject {

    let delegateHolder: ManagedContextRelatedObjectHolder<NSFetchedResultsController<ObservationEntry>>

    @objc init(onlyWithImages: Bool) {
        delegateHolder = ManagedContextRelatedObjectHolder(objectProvider: {
            LogItemService.shared().setupObservationResultsController(onlyWithImages: onlyWithImages)
        })
    }

    @objc func getObject() -> NSFetchedResultsController<ObservationEntry> {
        return delegateHolder.getObject()
    }
}
