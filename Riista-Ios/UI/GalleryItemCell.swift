import Foundation

import MaterialComponents

class GalleryItemCell: MDCCardCollectionCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var leftButton: MDCButton!
    @IBOutlet weak var rightButton: MDCButton!

    var itemType: RiistaEntryType?
    var item: DiaryEntryBase?

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

        RiistaUtils.loadEventImage(diaryEntry, for: imageView, completion: { image in
            self.imageView.image = image
        })

        return self
    }

    func setupFrom(observation: ObservationEntry, parent: UIViewController) -> UICollectionViewCell {
        self.parent = parent

        itemType = RiistaEntryTypeObservation
        item = observation

        RiistaUtils.loadEventImage(observation, for: imageView, completion: { image in
            self.imageView.image = image
        })

        return self
    }

    func setupFrom(srva: SrvaEntry, parent: UIViewController) -> UICollectionViewCell {
        self.parent = parent

        itemType = RiistaEntryTypeSrva
        item = srva

        RiistaUtils.loadEventImage(srva, for: imageView, completion: { image in
            self.imageView.image = image
        })

        return self
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
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let dest = sb.instantiateViewController(withIdentifier: "ImageFullController") as? ImageFullViewController
        dest?.item = self.item

        let segue = UIStoryboardSegue(identifier: "", source: parent!, destination: dest!, performHandler: {
            self.parent?.navigationController?.pushViewController(dest!, animated: true)
        })
        segue.perform()
    }
}
