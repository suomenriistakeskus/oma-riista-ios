import Foundation
import FirebaseMessaging

/**
 * A class that provides tab navigation and also is able to update navigation item when tabs are changed.
 */
@objc class BaseTabBarViewController: UITabBarController, UITabBarControllerDelegate {

    override var selectedIndex: Int {
        didSet {
            updateNavigationBar(for: selectedIndex)
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateNavigationBarForCurrentlySelectedViewController()
    }


    // MARK: - Updating navigation item

    func updateNavigationBarForCurrentlySelectedViewController() {
        if let viewController = self.selectedViewController {
            updateNavigationBar(for: viewController)
        }
    }

    func updateNavigationBar(for index: Int) {
        if let viewcontroller = self.viewControllers?.getOrNil(index: index) {
            updateNavigationBar(for: viewcontroller)
        }
    }

    func updateNavigationBar(for viewController: UIViewController) {
        self.navigationItem.title = viewController.navigationItem.title
        self.navigationItem.titleView = viewController.navigationItem.titleView
        self.navigationItem.leftBarButtonItems = viewController.navigationItem.leftBarButtonItems
        self.navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems
    }


    // MARK: - UITabBarControllerDelegate

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateNavigationBar(for: viewController)
    }

    // MARK: - setup

    func setup() {
        self.delegate = self
    }
}
