import Foundation
import AcknowList
import GoogleMaps

/**
 A view controller for managing and embedding AcknowListViewController (which only seems to support Swift).
 */
@objc class ThirdPartyLicensesController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let acknowListController = AcknowListViewController(fileNamed: "Pods-Riista-acknowledgements")

        injectProperGoogleMapsLicense(acknowListController: acknowListController)

        // setup header and footer before adding as child
        acknowListController.headerText = nil
        acknowListController.footerText = nil

        addChild(acknowListController)
        acknowListController.view.frame = self.view.frame
        view.addSubview(acknowListController.view)
    }

    private func injectProperGoogleMapsLicense(acknowListController: AcknowListViewController) {
        let googleMapsTitle = "GoogleMaps"
        let googlemapsAcknowledgement = Acknow(title: googleMapsTitle,
                                               text: GMSServices.openSourceLicenseInfo())

        var googleMapsLicenseInjected = false
        acknowListController.acknowledgements = acknowListController.acknowledgements.map { acknowledgement in
            if (acknowledgement.title == googleMapsTitle) {
                googleMapsLicenseInjected = true
                return googlemapsAcknowledgement
            }
            return acknowledgement
        }


        if (!googleMapsLicenseInjected) {
            acknowListController.acknowledgements = [googlemapsAcknowledgement]
        }
    }
}
