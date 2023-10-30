import Foundation
import Async


extension Thread {
    /**
     * Calls the given block on main thread.
     */
    static func onMainThread(_ block: @escaping () -> Void) {
        if (Thread.isMainThread) {
            block()
        } else {
            Async.main(after: nil, block)
        }
    }
}


/**
 * Creates a new `OnCompleted` completion handler that calls the completion handler on the main thread.
 */
func handleOnMainThread(_ completionHandler: @escaping OnCompleted) -> OnCompleted {
    return {
        Thread.onMainThread {
            completionHandler()
        }
    }
}


/**
 * Creates a new `OnCompletedWithError` completion handler that transfers the handling of the error to the main thread.
 */
func handleOnMainThread(_ completionHandler: @escaping OnCompletedWithError) -> OnCompletedWithError {
    return { error in
        Thread.onMainThread {
            completionHandler(error)
        }
    }
}

/**
 * Creates a new `OnCompletedWithResultAndError` completion handler that transfers
 * the handling of the result and error to the main thread.
 */
func handleOnMainThread<T : AnyObject>(
    _ completionHandler: @escaping OnCompletedWithResultAndError<T>
) -> OnCompletedWithResultAndError<T> {
    return { result, error in
        Thread.onMainThread {
            completionHandler(result, error)
        }
    }
}
