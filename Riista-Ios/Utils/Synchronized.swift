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
     *
     * Nested calls to apply are not supported (will result in deadlock).
     */
    func apply(_ applyFunc: (inout T) -> Void) {
        barrier.sync {
            applyFunc(&value)
        }
    }
}


class SynchronizedInt : Synchronized<Int> {

    /**
     * Decrements the value and returns the value after operation.
     */
    @discardableResult
    func decrementAndGet() -> Int {
        var result: Int = 0

        apply { value in
            result = value - 1
            value = result
        }

        return result
    }

    /**
     * Increments the value and returns the value after operation.
     */
    @discardableResult
    func incrementAndGet() -> Int {
        var result: Int = 0

        apply { value in
            result = value + 1
            value = result
        }

        return result
    }
}
