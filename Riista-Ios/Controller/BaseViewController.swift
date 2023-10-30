import Foundation

@objc open class BaseViewController: UIViewController {

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        breadcrump()
    }
}

@objc extension UIViewController {
    @objc func breadcrump(_ breadcrumb: String = #function) {
        let breadcrumbWithSelf =  "\(String.init(describing: type(of: self))) - \(breadcrumb)"
        CrashlyticsHelper.breadcrumb(breadcrumb: breadcrumbWithSelf)
    }
}
