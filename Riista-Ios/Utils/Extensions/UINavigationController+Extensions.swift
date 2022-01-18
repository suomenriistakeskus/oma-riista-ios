import Foundation

extension UINavigationController {
    @objc var rootViewController: UIViewController? {
        return viewControllers.first
    }


    /**
     * Replaces the view controllers that are after the given `parentViewController` with
     * the given `childViewControllers`
     *
     * `parentViewController` is required to exist in the navigation stack (will do nothing if it doesn't exist) in the stack.
     *
     * Example:
     * - let the navigation stack be: [A, B, C, D]
     * - replaceViewControllers(parent: B, childViewControllers: [E, F])
     * - stack after operation: [A, B, E, F]
     */
    func replaceViewControllers(
        parentViewController: UIViewController,
        childViewControllers: [UIViewController],
        animated: Bool
    ) {
        guard let parentIndex = viewControllers.firstIndex(of: parentViewController) else {
            print("parentViewController not in viewControllers, returning!")
            return
        }

        let newViewControllers = Array(viewControllers[0 ... parentIndex]) + childViewControllers
        setViewControllers(newViewControllers, animated: animated)
    }

    /**
     * Replaces the view controllers that are after the given `parentViewController` with
     * the given `childViewController`
     *
     * `parentViewController` is required to exist in the navigation stack (will do nothing if it doesn't exist) in the stack.
     *
     * Example:
     * - let the navigation stack be: [A, B, C, D]
     * - replaceViewControllers(parent: B, childViewControllers: E)
     * - stack after operation: [A, B, E]
     */
    func replaceViewControllers(
        parentViewController: UIViewController,
        childViewController: UIViewController,
        animated: Bool
    ) {
        replaceViewControllers(parentViewController: parentViewController,
                               childViewControllers: [childViewController],
                               animated: animated)
    }
}
