import Foundation

typealias ObjectProvider<T> = () -> T

/**
 A class for holding ManagedObjectContext related object and keeping track of whether ManagedObjectContext changes.
 The holder will ask for a new object in case ManagedObjectContext changes.
 */
class ManagedContextRelatedObjectHolder<T> {
    private var managedObjectContext: NSManagedObjectContext?
    private var objectProvider: ObjectProvider<T>
    private var object: T

    init(objectProvider: @escaping ObjectProvider<T>) {
        self.managedObjectContext = ManagedContextRelatedObjectHolder<T>.getCurrentManagedObjectContext()
        self.objectProvider = objectProvider
        self.object = objectProvider()
    }

    public func getObject() -> T {
        let currentContext = ManagedContextRelatedObjectHolder<T>.getCurrentManagedObjectContext()
        if (self.managedObjectContext != currentContext) {
            self.managedObjectContext = currentContext
            self.object = objectProvider()
        }

        return object
    }

    private static func getCurrentManagedObjectContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! RiistaAppDelegate
        return appDelegate.managedObjectContext
    }
}
