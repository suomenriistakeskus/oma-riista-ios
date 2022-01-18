import Foundation


/**
 * A helper class for situations where class would need multiple delegates.
 *
 * Keeps weak references to delegates.
 */
class MultiDelegate<T> {
    private var delegates = [Weak]()

    var delegateCount: Int {
        get {
            delegates.count
        }
    }

    func invoke(_ invocation: (T) -> Void) {
        var nilDelegatesObserved = false

        delegates.forEach { weakDelegate in
            if let delegate = weakDelegate.value as? T {
                invocation(delegate)
            } else {
                nilDelegatesObserved = true
            }
        }

        if (nilDelegatesObserved) {
            removeGarbageCollectedDelegates()
        }
    }

    func contains(delegate: T) -> Bool {
        let delegateObject = getDelegateObject(delegate)

        for weakDelegate in delegates {
            if let candidate = weakDelegate.value, candidate === delegateObject {
                return true
            }
        }

        return false
    }

    /**
     * Doesn't allow adding the same delegate twice.
     */
    func add(delegate: T) {
        if (!contains(delegate: delegate)) {
            delegates.append(Weak(value: getDelegateObject(delegate)))
        } else {
            print("Delegate already exists, not adding it second time.")
        }
    }

    func remove(delegate: T) {
        let delegateObject = getDelegateObject(delegate)
        delegates.removeAll { weakDelegate in
            weakDelegate.value === delegateObject
        }
    }

    private func getDelegateObject(_ delegate: T) -> AnyObject {
        return delegate as AnyObject
    }

    private func removeGarbageCollectedDelegates() {
        delegates.removeAll { weakDelegate in
            weakDelegate.value == nil
        }
    }
}
