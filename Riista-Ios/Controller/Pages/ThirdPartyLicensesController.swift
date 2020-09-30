import Foundation
import AcknowList

/**
 A view controller for managing and embedding AcknowListViewController (which only seems to support Swift).
 */
@objc class ThirdPartyLicensesController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let acknowListController = AcknowListViewController(fileNamed: "Pods-Riista-acknowledgements")

        // setup header and footer before adding as child
        acknowListController.headerText = nil
        acknowListController.footerText = nil

        addChild(acknowListController)
        acknowListController.view.frame = self.view.frame
        view.addSubview(acknowListController.view)
    }
}
