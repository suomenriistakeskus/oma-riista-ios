import Foundation
import OverlayContainer


/**
 * A helper for managing bottom sheets.
 *
 * Heavily inspired by examples in OverlayContainer repository.
 */
class BottomSheetHelper: NSObject,
    UIViewControllerTransitioningDelegate,
    OverlayTransitioningDelegate,
    OverlayContainerViewControllerDelegate,
    OverlayContainerSheetPresentationControllerDelegate {

    enum Notch: Int, CaseIterable {
        case dismissNotch // required for dismissing
         case medium, maximum
    }

    private weak var hostViewController: UIViewController?

    init(hostViewController: UIViewController) {
        self.hostViewController = hostViewController
    }

    func display(contentViewController: UIViewController) {
        let container = OverlayContainerViewController()
        container.viewControllers = [contentViewController]
        container.delegate = self
        container.moveOverlay(toNotchAt: Notch.medium.rawValue, animated: false)
        container.transitioningDelegate = self
        container.modalPresentationStyle = .custom

        hostViewController?.present(container, animated: true, completion: nil)
    }

    func dismiss(onCompleted: OnCompleted? = nil) {
        if let hostViewController = hostViewController,
           hostViewController.presentedViewController != nil {
            hostViewController.dismiss(animated: true, completion: onCompleted)
        } else {
            onCompleted?()
        }
    }

    // MARK: - UIViewControllerTransitioningDelegate

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let dimmingView = TransparentOverlayContainerSheetDimmingView()
        dimmingView.minimumAlpha = 0.3
        dimmingView.maximumAlpha = 0.6
        let controller = OverlayContainerSheetPresentationController(
            dimmingView: dimmingView,
            presentedViewController: presented,
            presenting: presenting
        )
        controller.sheetDelegate = self
        return controller
    }


    // MARK: - OverlayContainerSheetPresentationControllerDelegate

    func overlayContainerSheetDismissalPolicy(
        for presentationController: OverlayContainerSheetPresentationController
    ) -> OverlayContainerSheetDismissalPolicy {
        var policy = ThresholdOverlayContainerSheetDismissalPolicy()
        policy.dismissingVelocity = .value(2400)
        // we need to have dismissNotch specified in order to allow index to go below
        // specified notch
        policy.dismissingPosition = .notch(index: Notch.medium.rawValue)
        return policy
    }


    // MARK: - OverlayTransitioningDelegate

    func overlayTargetNotchPolicy(
        for overlayViewController: UIViewController
    ) -> OverlayTranslationTargetNotchPolicy? {
        ActivityControllerLikeTargetNotchPolicy()
    }


    // MARK: - OverlayContainerViewControllerDelegate

    func numberOfNotches(in containerViewController: OverlayContainerViewController) -> Int {
        Notch.allCases.count
    }

    func overlayContainerViewController(
        _ containerViewController: OverlayContainerViewController,
        transitioningDelegateForOverlay overlayViewController: UIViewController
    ) -> OverlayTransitioningDelegate? {
        self
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        heightForNotchAt index: Int,
                                        availableSpace: CGFloat) -> CGFloat {
        switch Notch.allCases[index] {
        case .dismissNotch:
            return (availableSpace - 200) / 4
        case .medium:
            return (availableSpace - 200) / 2
        case .maximum:
            return availableSpace - 200
        }
    }

    func overlayContainerViewController(
        _ containerViewController: OverlayContainerViewController,
        scrollViewDrivingOverlay overlayViewController: UIViewController
    ) -> UIScrollView? {
        return (overlayViewController as? ContainsTableViewForBottomsheet)?.tableView
    }
}

struct ActivityControllerLikeTargetNotchPolicy: OverlayTranslationTargetNotchPolicy {

    func targetNotchIndex(using context: OverlayContainerContextTargetNotchPolicy) -> Int {
        let movesUp = context.velocity.y < 0
        if movesUp {
            // The container can easily move up
            return RushingForwardTargetNotchPolicy().targetNotchIndex(using: context)
        } else {
            // The container can not easily move down
            let defaultPolicy = RushingForwardTargetNotchPolicy()
            defaultPolicy.minimumVelocity = 2400
            return defaultPolicy.targetNotchIndex(using: context)
        }
    }
}
