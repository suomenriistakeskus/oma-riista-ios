import Foundation
import Async

/**
 * A class for helping to observe dismissal of viewcontrollers app has no access to. One example of these
 * could be e.g. limited PhotoLibrary picker (PHPhotoLibrary.shared().presentLimitedLibraryPicker(..)) which
 * does not have any delegate methods for telling when the picker has been dismissed.
 *
 * Dismiss observation is made by polling i.e. let's check periodically whether the same viewcontroller is still being presented.
 */
class PresentedViewControllerDismissObserver: NSObject {

    private let dismissObservationIntervalSeconds: Double
    private weak var presentedViewController: UIViewController? = nil
    private var observing: Bool = false

    var debugPrint: Bool = false

    init(dismissObservationIntervalSeconds: Double) {
        self.dismissObservationIntervalSeconds = dismissObservationIntervalSeconds
    }

    /**
     * Starts observing dismissal of presented view controller after given amount of seconds.
     */
    func startObservePresentedViewControllerDismissal(presentingViewController: UIViewController,
                                                      shouldBePresentingAfterSeconds: Double = 1.0) {
        Async.main(after: shouldBePresentingAfterSeconds) { [weak self] in
            let presentedViewController = presentingViewController.presentedViewController
            if (self == nil) {
                // garbage collected i.e. probably already dismissed. Nothing to do.
                return
            } else if (presentedViewController == nil) {
                self!.onNoPresentedViewControllerToObserve()
                return
            }

            self?.presentedViewController = presentedViewController
            self?.observing = true
            self?.onDismissObservationStarted()

            self?.observePresentedViewControllerDismissal(presentingViewController)
        }
    }

    func stopPresentedViewControllerDismissObservation() {
        self.observing = false
    }

    func observePresentedViewControllerDismissal(_ presentingViewController: UIViewController) {
        if (!observing) {
            onDismissObservationStopped()
            clearAfterStop()
            return
        }

        let initialViewController = self.presentedViewController
        let currentViewController = presentingViewController.presentedViewController

        // explicitly check for nil since initially presented viewcontroller may become nil if dismissed
        if (initialViewController != nil && initialViewController == currentViewController) {
            // still presenting, check dismiss status again after a while
            debugPrint(prefix: "Still presenting", currentViewController)
            Async.main(after: dismissObservationIntervalSeconds) { [weak self] in
                if let self = self {
                    self.observePresentedViewControllerDismissal(presentingViewController)
                } else {
                    // nothing really we can do here. The observer was assumedly
                    // garbage collected between two observation checks
                }
            }
        } else {
            debugPrint(prefix: "Presented ViewController dismissed", currentViewController)
            self.onPresentedViewControllerDismissed()
            clearAfterStop()
        }
    }

    func onNoPresentedViewControllerToObserve() {
        if (debugPrint) {
            print("No presented ViewController. Cannot observe dismissal")
        }
    }

    func onDismissObservationStarted() {
        debugPrint(prefix: "Starting to observe", self.presentedViewController)
    }

    func onDismissObservationStopped() {
        debugPrint(prefix: "Observation stopped", self.presentedViewController)
    }

    func onPresentedViewControllerDismissed() {
        // nop
    }

    private func clearAfterStop() {
        self.observing = false
        self.presentedViewController = nil
    }

    private func debugPrint(prefix: String, _ currentlyPresentedViewController: UIViewController?) {
        if (!debugPrint) {
            return
        }

        // initially presented VC may be released at any time so it is possible that last debug
        // prints print <nil> instead of the address of initially presented VC
        print("\(prefix). Currently presented VC = \(viewControllerIdentity(currentlyPresentedViewController)), " +
                "initially presented VC = \(viewControllerIdentity(self.presentedViewController))")
    }

    private func viewControllerIdentity(_ viewController: UIViewController?) -> Any {
        // address should be ok
        return viewController == nil ? "<nil>" : Unmanaged.passUnretained(viewController!).toOpaque()
    }
}
