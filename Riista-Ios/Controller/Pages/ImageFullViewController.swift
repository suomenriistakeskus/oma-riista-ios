import Foundation
import RiistaCommon

class ImageFullViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    @objc var item: DiaryEntryBase?
    var entityImage: EntityImage? = nil

    override func viewDidLoad() {
        self.imageView.contentMode = .scaleAspectFit
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.setRightBarButtonItems([], animated: false)

        if let entityImage = entityImage {
            ImageUtils.loadEntityImage(
                image: entityImage,
                imageView: imageView,
                options: ImageLoadOptions.aspectFitted(size: imageView.bounds.size),
                onSuccess: { image in
                    self.imageView.image = image
                },
                onFailure: { failureReason in
                    print("failed to load fullscreen image for entityImage")
                }
            )
        } else {
            ImageUtils.loadEventImage(
                item,
                for: imageView,
                options: ImageLoadOptions.aspectFitted(size: imageView.bounds.size),
                onSuccess: { image in
                    self.imageView.image = image
                },
                onFailure: { failureReason in
                    print("failed to load fullscreen image for entry")
                }
            )
        }
    }
}
