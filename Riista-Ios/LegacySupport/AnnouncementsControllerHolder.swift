import Foundation

/**
 A helper for objective c to allow instantiation and usage of
 ManagedContextRelatedObjectHolder<NSFetchedResultsController<Announcement>>
 */
@objc class AnnouncementsControllerHolder: NSObject {

    let delegateHolder: ManagedContextRelatedObjectHolder<NSFetchedResultsController<Announcement>>

    override init() {
        delegateHolder = ManagedContextRelatedObjectHolder(objectProvider: {
            Self.createAnnouncementFetchController()
        })
    }

    @objc func getObject() -> NSFetchedResultsController<Announcement> {
        return delegateHolder.getObject()
    }

    private class func createAnnouncementFetchController() -> NSFetchedResultsController<Announcement> {
        print("Creating announcement fetch controller")
        let appDelegate = UIApplication.shared.delegate as! RiistaAppDelegate
        guard let managedContext = appDelegate.managedObjectContext else {
            fatalError("No managed object context, cannot create announcement fetch controller")
        }

        let fetchRequest = NSFetchRequest<Announcement>(entityName: "Announcement")
        fetchRequest.fetchBatchSize = 20

        let sortDescriptor = NSSortDescriptor(key: "pointOfTime", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let fetchedResultsController = NSFetchedResultsController<Announcement>(
            fetchRequest: fetchRequest,
            managedObjectContext: managedContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        return fetchedResultsController
    }
}
