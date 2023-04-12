import Foundation


protocol EntityFilterChangeListener: AnyObject {
    /**
     * Notifies about entity filter change.
     *
     * It is possible that newFilter is equal to oldFilter. This is the case when registering as a listener to SharedEntityFilterState
     * by calling addListener(<listener>, notify: true)
     */
    func onEntityFilterChanged(change: EntityFilterChange)
}
