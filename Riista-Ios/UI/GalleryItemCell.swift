import Foundation
import MaterialComponents
import RiistaCommon

fileprivate enum GalleryItemModel {
    case commonEntry(localId: KotlinLong, itemType: FilterableEntityType, image: EntityImage)
    case none

    static func == (lhs: GalleryItemModel, rhs: GalleryItemModel) -> Bool {
        switch (lhs, rhs) {
        case (let commonEntry(l_localId, l_itemType, _), let commonEntry(r_localId, r_itemType, _)):
            return l_localId == r_localId && l_itemType == r_itemType
        case (.none, .none):
            return true
        default:
            return false
        }
    }

    static func != (lhs: GalleryItemModel, rhs: GalleryItemModel) -> Bool {
        !(lhs == rhs)
    }
}

class GalleryItemCell: MDCCardCollectionCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var leftButton: MDCButton!
    @IBOutlet weak var rightButton: MDCButton!

    private var displayedItem: GalleryItemModel = .none
    var imageLoadedSuccessfully: Bool?

    weak var parent: UIViewController?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.backgroundColor = .white

        self.cornerRadius = 4.0
        self.setBorderWidth(1.0, for: .normal)
        self.setBorderColor(UIColor.applicationColor(GreyLight), for: .normal)

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.rightButtomClick(_:)))
        imageView.addGestureRecognizer(tap)
    }

    @discardableResult
    func setupFrom(harvest: CommonHarvest, parent: UIViewController) -> UICollectionViewCell {
        self.parent = parent

        if let localId = harvest.localId, let primaryImage = harvest.images.primaryImage {
            displayedItem = .commonEntry(localId: localId, itemType: .harvest, image: primaryImage)
        } else {
            displayedItem = .none
        }

        loadImage()

        return self
    }

    @discardableResult
    func setupFrom(observation: CommonObservation, parent: UIViewController) -> UICollectionViewCell {
        self.parent = parent

        if let localId = observation.localId, let primaryImage = observation.images.primaryImage {
            displayedItem = .commonEntry(localId: localId, itemType: .observation, image: primaryImage)
        } else {
            displayedItem = .none
        }

        loadImage()

        return self
    }

    @discardableResult
    func setupFrom(srva: CommonSrvaEvent, parent: UIViewController) -> UICollectionViewCell {
        self.parent = parent

        if let localId = srva.localId, let primaryImage = srva.images.primaryImage {
            displayedItem = .commonEntry(localId: localId, itemType: .srva, image: primaryImage)
        } else {
            displayedItem = .none
        }

        loadImage()

        return self
    }

    /**
     * Loads the image from the current item. Only displays the loaded image if item is still the same.
     */
    func loadImage() {
        // loading may take time, hide image that may remain from
        // previous cell use
        imageView.image = nil

        let itemToDisplay = displayedItem

        switch itemToDisplay {
        case .commonEntry(_, _, let primaryImage):
            ImageUtils.loadEntityImage(
                image: primaryImage,
                imageView: imageView,
                options: ImageLoadOptions.aspectFilled(size: imageView.bounds.size),
                onSuccess: { [weak self] image in
                    self?.setDisplayedImage(image, itemModel: itemToDisplay)
                },
                onFailure: { [weak self] failureReason in
                    self?.displayImageLoadFailedIndicator(itemModel: itemToDisplay)
                }
            )
        case .none:
            break
        }
    }

    private func setDisplayedImage(_ image: UIImage, itemModel: GalleryItemModel) {
        if (itemModel != self.displayedItem) {
            // image loaded but for a cell that was already reused
            return
        }

        imageView.contentMode = .scaleAspectFill
        imageView.image = image
        imageLoadedSuccessfully = true
    }

    private func displayImageLoadFailedIndicator(itemModel: GalleryItemModel) {
        if (itemModel != self.displayedItem) {
            // image loaded but for a cell that was already reused
            return
        }

        imageView.contentMode = .center
        imageView.image = UIImage(named: "missing-image-error")
        imageLoadedSuccessfully = false
    }

    @IBAction func leftButtomClick(_ sender: AnyObject?) {
        switch displayedItem {
        case .commonEntry(let localId, let itemType, _):
            if (itemType == .harvest) {
                viewHarvest(localId: localId)
            } else if (itemType == .observation) {
                viewObservation(localId: localId)
            } else if (itemType == .srva) {
                viewSrva(localId: localId)
            } else {
                print("Unexpected itemType \(itemType) for .commonEntry (left click)")
            }
        case .none:
            break
        }
    }

    private func viewHarvest(localId: KotlinLong) {
        let viewController = ViewHarvestViewController(harvestId: localId.int64Value)
        self.parent?.navigationController?.pushViewController(viewController, animated: true)
    }

    private func viewObservation(localId: KotlinLong) {
        let viewController = ViewObservationViewController(observationId: localId.int64Value)
        self.parent?.navigationController?.pushViewController(viewController, animated: true)
    }

    private func viewSrva(localId: KotlinLong) {
        let viewController = ViewSrvaEventViewController(srvaEventId: localId.int64Value)
        self.parent?.navigationController?.pushViewController(viewController, animated: true)
    }

    @IBAction func rightButtomClick(_ sender: AnyObject?) {
        if (!(imageLoadedSuccessfully ?? false)) {
            print("Cannot display image in fullscreen, image could not be loaded")
            return
        }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let dest = sb.instantiateViewController(withIdentifier: "ImageFullController") as! ImageFullViewController

        switch displayedItem {
        case .commonEntry(_, _, let primaryImage):
            dest.entityImage = primaryImage
        case .none:
            break
        }

        let segue = UIStoryboardSegue(identifier: "", source: parent!, destination: dest, performHandler: {
            self.parent?.navigationController?.pushViewController(dest, animated: true)
        })
        segue.perform()
    }
}
