import Foundation

class ImageFullViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    @objc var item: DiaryEntryBase?

    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.setRightBarButtonItems([], animated: false)

        RiistaUtils.loadEventImage(item, for: imageView, completion: { image in
            self.imageView.image = image
        })
    }
}
