import Foundation


/**
 * A class that allows notifying about entity filter changes.
 */
class EntityFilterChangeNotifier {
    /**
     * The filter listeners
     */
    private let listeners = MultiDelegate<EntityFilterChangeListener>()

    /**
     * Adds a EntityFilterChangeListener.
     *
     * Will keep a weak reference to listener.
     */
    func addEntityFilterChangeListener(_ listener: EntityFilterChangeListener) {
        listeners.add(delegate: listener)
    }

    func removeEntityFilterChangeListener(_ listener: EntityFilterChangeListener) {
        listeners.remove(delegate: listener)
    }

    func notifyEntityFilterChanged(change: EntityFilterChange) {
        listeners.invoke { listener in
            listener.onEntityFilterChanged(change: change)
        }
    }
}
