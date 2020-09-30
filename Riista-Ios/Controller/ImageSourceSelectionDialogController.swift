import Foundation

import MaterialComponents.MaterialButtons

class ImageSourceSelectionDialogController: UIViewController {

    @objc enum ImageSource: Int {
        case camera
        case gallery
    }

    @IBOutlet weak var dialogTitle: UILabel!
    @IBOutlet weak var cameraSourceButton: MDCButton!
    @IBOutlet weak var gallerySourceButton: MDCButton!

    var containerScheme = MDCContainerScheme()

    @objc var completionHandler: ((_ imageSource: ImageSource) -> Void)!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        containerScheme.colorScheme = MDCSemanticColorScheme()
        containerScheme.typographyScheme = MDCTypographyScheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraSourceButton.applyTextTheme(withScheme: AppTheme.shared.buttonContainerScheme())
        gallerySourceButton.applyTextTheme(withScheme: AppTheme.shared.buttonContainerScheme())

        cameraSourceButton.isUppercaseTitle = false
        gallerySourceButton.isUppercaseTitle = false

        dialogTitle.text =  RiistaBridgingUtils.RiistaLocalizedString(forkey: "ChooseImageSource")
        cameraSourceButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "CameraSource"), for: .normal)
        gallerySourceButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "GallerySource"), for: .normal)

        cameraSourceButton.addTarget(self, action: #selector(onButtonTap(_:)), for: .touchUpInside)
        gallerySourceButton.addTarget(self, action: #selector(onButtonTap(_:)), for: .touchUpInside)

    }

    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 400.0, height: 175.0)
        }
        set {
            super.preferredContentSize = newValue
        }
    }

    @objc func onButtonTap(_ sender: MDCButton?) {
        self.dismiss(animated: true) {
            if (sender == self.cameraSourceButton) {
                self.completionHandler?(ImageSource.camera)
            } else if (sender == self.gallerySourceButton) {
                self.completionHandler?(ImageSource.gallery)
            }
        }
    }
}
