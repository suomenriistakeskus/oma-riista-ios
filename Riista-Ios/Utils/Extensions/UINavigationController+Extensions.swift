import Foundation

extension UINavigationController {
    @objc var rootViewController: UIViewController? {
        return viewControllers.first
    }

    /**
     * Tries to find a UIViewController that implements the given type T.
     *
     * Checks also following view controllers:
     * - UITabBarController.selectedViewController
     */
    func findViewController<T>() -> T? {
        for viewController in viewControllers.reversed() {
            if let result = viewController as? T {
                return result
            }

            // it is possible that desired viewcontroller is hosted in UITabBarController
            if let result = (viewController as? UITabBarController)?.selectedViewController as? T {
                return result
            }
        }

        return nil
    }

    /**
     * Pops to a viewcontroller that implements the specified type T.
     *
     * Supports also UITabBarController i.e. if UITabBarController.selectedViewController implements the type, will pop to that.
     */
    func popToViewControllerWithType<T>(target: T, animated: Bool) {
        // require pop target to be UIViewController
        guard let viewControllerTarget = target as? UIViewController else {
            env.crashOnDev("target IS NOT UIViewController!")
            return
        }

        for viewController in viewControllers.reversed() {
            if (viewControllerTarget === viewController) {
                popToViewController(viewController, animated: animated)
                break
            }

            // it is possible that desired viewcontroller is hosted in UITabBarController
            if let tabBarController = viewController as? UITabBarController {
                if (viewControllerTarget === tabBarController.selectedViewController) {
                    popToViewController(tabBarController, animated: animated)
                    break
                }
            }
        }
    }

    /**
     * Replaces the `viewControllerToPop` and subsequent view controllers with the given `childViewControllers`.
     *
     * `viewControllerToPop` is required to exist in the navigation stack (will do nothing if it doesn't exist) in the stack.
     *
     * Example:
     * - let the navigation stack be: [A, B, C, D]
     * - replaceViewControllers(viewControllerToPop: B, childViewControllers: [E, F])
     * - stack after operation: [A, E, F]
     */
    func replaceViewController(
        viewControllerToPop: UIViewController,
        childViewControllers: [UIViewController],
        animated: Bool
    ) {
        guard let popIndex = viewControllers.firstIndex(of: viewControllerToPop) else {
            print("viewControllerToPop not in viewControllers, returning!")
            return
        }

        let newViewControllers = Array(viewControllers.prefix(upTo: popIndex)) + childViewControllers
        setViewControllers(newViewControllers, animated: animated)
    }

    /**
     * Replaces the view controllers that are after the given `parentViewController` with
     * the given `childViewControllers`
     *
     * `parentViewController` is required to exist in the navigation stack (will do nothing if it doesn't exist) in the stack.
     *
     * Example:
     * - let the navigation stack be: [A, B, C, D]
     * - replaceViewControllers(parentViewController: B, childViewControllers: [E, F])
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


extension UINavigationController {
    func showDatePicker(datePickerMode: UIDatePicker.Mode,
                        currentDate: Foundation.Date,
                        minDate: Foundation.Date? = nil,
                        maxDate: Foundation.Date? = nil,
                        onPicked: @escaping (Foundation.Date) -> Void) {
        let selectAction = RMAction<UIDatePicker>(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK"),
            style: .done
        ) { controller in
            onPicked(controller.contentView.date)
        }

        let cancelAction = RMAction<UIDatePicker>(
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "Cancel"),
            style: .default)
        { controller in
            // nop
        }

        guard let dateSelectionViewController: RMDateSelectionViewController = RMDateSelectionViewController(
            style: .default,
            select: selectAction,
            andCancel: cancelAction
        ) else {
            print("Failed to create RMDateSelectionViewController")
            return
        }

        dateSelectionViewController.datePicker.apply({ datepicker in
            datepicker.date = currentDate
            datepicker.locale = RiistaSettings.locale()
            datepicker.timeZone = RiistaDateTimeUtils.finnishTimezone()
            datepicker.minimumDate = minDate
            datepicker.maximumDate = maxDate
            datepicker.datePickerMode = datePickerMode
            if #available(iOS 13.4, *) {
                datepicker.preferredDatePickerStyle = .wheels
            }
        })

        self.present(dateSelectionViewController, animated: true, completion: nil)
    }
}
