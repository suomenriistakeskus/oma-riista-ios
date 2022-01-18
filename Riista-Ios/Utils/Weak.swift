import Foundation


/**
 * A weak reference to a class.
 */
class Weak {
    weak var value: AnyObject?

    init(value: AnyObject) {
        self.value = value
    }
}
