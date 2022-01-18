import Foundation


class Synchronized<T> {
    private let barrier: DispatchQueue
    private var value: T

    init(label: String, initialValue: T) {
        self.barrier = DispatchQueue(label: label)
        self.value = initialValue
    }

    /**
     * Provides a synchronized, mutating access to the value.
     */
    func apply(_ applyFunc: (inout T) -> Void) {
        barrier.sync {
            applyFunc(&value)
        }
    }
}
