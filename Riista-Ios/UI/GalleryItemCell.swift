import Foundation

import MaterialComponents

class GalleryItemCell: MDCCardCollectionCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var leftButton: MDCButton!
    @IBOutlet weak var rightButton: MDCButton!

    var itemType: RiistaEntryType?
    var item: DiaryEntryBase?
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

    func setupFrom(diaryEntry: DiaryEntry, parent: UIViewController) -> UICollectionViewCell {
        self.parent = parent

        itemType = RiistaEntryTypeHarvest
        item = diaryEntry
        loadImage()

        return self
    }

    func setupFrom(observation: ObservationEntry, parent: UIViewController) -> UICollectionViewCell {
        self.parent = parent

        itemType = RiistaEntryTypeObservation
        item = observation
        loadImage()

        return self
    }

    func setupFrom(srva: SrvaEntry, parent: UIViewController) -> UICollectionViewCell {
        self.parent = parent

        itemType = RiistaEntryTypeSrva
        item = srva
        loadImage()

        return self
    }

    /**
     * Loads the image from the current item. Only displays the loaded image if item is still the same.
     */
    func loadImage() {
        let entry = self.item

        // loading may take time, hide image that may remain from
        // previous cell use
        imageView.image = nil

        ImageUtils.loadEventImage(
            entry, for: imageView,
            options: ImageLoadOptions.aspectFilled(size: imageView.bounds.size),
            onSuccess: { [weak self, weak entry] image in
                self?.setDisplayedImage(image, entry: entry)
            },
            onFailure: { [weak self] failureReason in
                self?.displayImageLoadFailedIndicator(entry: entry)
            }
        )
    }

    func setDisplayedImage(_ image: UIImage, entry: DiaryEntryBase?) {
        guard let entry = entry else { return }
        if (entry != self.item) {
            // image loaded but for a cell that was already reused
            return
        }

        imageView.contentMode = .scaleAspectFill
        imageView.image = image
        imageLoadedSuccessfully = true
    }

    func displayImageLoadFailedIndicator(entry: DiaryEntryBase?) {
        guard let entry = entry else { return }
        if (entry != self.item) {
            // image loaded but for a cell that was already reused
            return
        }

        imageView.contentMode = .center
        imageView.image = UIImage(named: "missing-image-error")
        imageLoadedSuccessfully = false
    }

    @IBAction func leftButtomClick(_ sender: AnyObject?) {
        switch itemType {
        case RiistaEntryTypeHarvest:
            let sb = UIStoryboard(name: "HarvestStoryboard", bundle: nil)
            let dest = sb.instantiateInitialViewController() as? RiistaLogGameViewController
            dest?.eventId = item?.objectID

            let segue = UIStoryboardSegue(identifier: "", source: parent!, destination: dest!, performHandler: {
                self.parent?.navigationController?.pushViewController(dest!, animated: true)
            })
            segue.perform()
        case RiistaEntryTypeObservation:
            let sb = UIStoryboard(name: "DetailsStoryboard", bundle: nil)
            let dest = sb.instantiateInitialViewController() as! DetailsViewController
            dest.observationId = item?.objectID

            let segue = UIStoryboardSegue(identifier: "", source: parent!, destination: dest, performHandler: {
                self.parent?.navigationController?.pushViewController(dest, animated: true)
            })
            segue.perform()
        case RiistaEntryTypeSrva:
            let sb = UIStoryboard(name: "DetailsStoryboard", bundle: nil)
            let dest = sb.instantiateInitialViewController() as! DetailsViewController
            dest.srvaId = item?.objectID

            let segue = UIStoryboardSegue(identifier: "", source: parent!, destination: dest, performHandler: {
                self.parent?.navigationController?.pushViewController(dest, animated: true)
            })
            segue.perform()
        default:
            break
        }
    }

    @IBAction func rightButtomClick(_ sender: AnyObject?) {
        if (!(imageLoadedSuccessfully ?? false)) {
            print("Cannot display image in fullscreen, image could not be loaded")
            return
        }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let dest = sb.instantiateViewController(withIdentifier: "ImageFullController") as? ImageFullViewController
        dest?.item = self.item

        let segue = UIStoryboardSegue(identifier: "", source: parent!, destination: dest!, performHandler: {
            self.parent?.navigationController?.pushViewController(dest!, animated: true)
        })
        segue.perform()
    }
}
