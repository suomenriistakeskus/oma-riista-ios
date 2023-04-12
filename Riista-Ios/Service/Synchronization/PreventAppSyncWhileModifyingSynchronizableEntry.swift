import Foundation

/**
 * Prevents automatic `AppSync` while attached viewcontroller is in navigation stack. Pushing more viewcontrollers does not cancel prevention.
 */
class PreventAppSyncWhileModifyingSynchronizableEntry {
    private let viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func onViewWillAppear() {
        if (viewController.isMovingToParent) {
            // only when pushing, not when popping _to_
            AppSync.shared.disableSyncPrecondition(.userIsNotModifyingSynchronizableEntry)
        }
    }

    func onViewWillDisappear() {
        if (viewController.isMovingFromParent) {
            // being popped from navigation stack, no longer modifying
            AppSync.shared.enableSyncPrecondition(.userIsNotModifyingSynchronizableEntry)
        }
    }
}
