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

        guard let entityImage = entityImage else {
            ImageUtils.loadEventImage(
                item, for: imageView,
                options: ImageLoadOptions.aspectFitted(size: imageView.bounds.size),
                onSuccess: { image in
                    self.imageView.image = image
                },
                onFailure: { failureReason in
                    print("failed to load fullscreen image for entry")
                })
            return
        }

        let delegate = UIApplication.shared.delegate as! RiistaAppDelegate
        let context = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        context.parent = delegate.managedObjectContext
        let diaryImage = entityImage.toDiaryImage(context: context)

        ImageUtils.loadDiaryImage(
            diaryImage,
            imageView: imageView,
            options: ImageLoadOptions.aspectFitted(size: imageView.bounds.size),
            onSuccess: { image in
                print("success!")
                self.imageView.image = image
            },
            onFailure: { failureReason in
                print("failed to load fullscreen image for entry")
            })
    }
}
