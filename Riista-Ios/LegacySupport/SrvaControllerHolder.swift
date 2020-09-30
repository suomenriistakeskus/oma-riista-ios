import Foundation

/**
 A helper for objective c to allow instantiation and usage of
 ManagedContextRelatedObjectHolder<NSFetchedResultsController<SrvaEntry>>
 */
@objc class SrvaControllerHolder: NSObject {

    let delegateHolder: ManagedContextRelatedObjectHolder<NSFetchedResultsController<SrvaEntry>>

    @objc init(onlyWithImages: Bool) {
        delegateHolder = ManagedContextRelatedObjectHolder(objectProvider: {
            LogItemService.shared().setupSrvaResultsController(onlyWithImages: onlyWithImages)
        })
    }

    @objc func getObject() -> NSFetchedResultsController<SrvaEntry> {
        return delegateHolder.getObject()
    }
}
