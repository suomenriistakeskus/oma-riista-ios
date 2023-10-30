import UIKit
import RiistaCommon

class GameLogItemCell: UITableViewCell {

    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speciesLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!

    @IBOutlet weak var stateView: UIView!
    @IBOutlet weak var stateImage: UIImageView!
    @IBOutlet weak var stateLabel: UILabel!

    @IBOutlet weak var uploadImage: UIImageView!

    @IBOutlet weak var timeLineUp: UIView!
    @IBOutlet weak var timeLineDown: UIView!

    // The id of the image for which the image is currently being fetched
    private var imageLoadedForId: String?

    static let dateFormatter = { () -> DateFormatter in
        let dateFormatter = DateFormatter(safeLocale: ())!
        dateFormatter.dateFormat = "dd.MM.yyyy"

        return dateFormatter
    }()

    static let timeFormatter = { () -> DateFormatter in
        let timeFormatter = DateFormatter(safeLocale: ())!
        timeFormatter.dateFormat = "HH:mm"

        return timeFormatter
    }()

    static let localizationProvider: LocalizedStringProvider = LocalizedStringProvider()

    /*
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
*/
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.frame = contentView.frame.insetBy(dx: 0, dy: 0)
    }

    func clearCurrentlyDisplayedData() {
        itemImage.image = nil
    }

    func setupFromHarvest(harvest: CommonHarvest, isFirst: Bool, isLast: Bool) {
        clearCurrentlyDisplayedData()

        loadImage(
            entityImage: harvest.images.primaryImage,
            speciesCode: harvest.species.knownSpeciesCodeOrNull()?.intValue
        )

        var nameText = "-"

        if let speciesCode = harvest.species.knownSpeciesCodeOrNull()?.intValue {
            let species = RiistaGameDatabase.sharedInstance()?.species(byId: speciesCode)
            nameText = RiistaUtils.name(withPreferredLanguage: species?.name)
            itemImage?.tintColor = nil
        }
        else {
            nameText = "-"
        }

        let specimenCount = harvest.amount
        if (specimenCount > 1) {
            nameText = "\(nameText) (\(specimenCount))"
        }

        speciesLabel.text = nameText

        dateLabel.text = GameLogItemCell.dateFormatter.string(from: harvest.pointOfTime.toFoundationDate())
        timeLabel.text = GameLogItemCell.timeFormatter.string(from: harvest.pointOfTime.toFoundationDate())

        infoLabel.text = ""
        infoLabel.isHidden = true

        stateLabel.text = nil
        stateImage.tintColor = UIColor.clear
        stateView.isHidden = true

        setupHarvestState(harvest: harvest)

        uploadImage.isHidden = harvest.modified == false

        timeLineUp.isHidden = isFirst
        timeLineDown.isHidden = isLast
    }


    func setupHarvestState(harvest: CommonHarvest) {
        guard let harvestState = harvest.harvestState else {
            return
        }

        stateLabel.text = harvestState.localized(stringProvider: Self.localizationProvider)
        if let indicatorColor = harvestState.indicatorColor_.toUIColor() {
            stateImage.tintColor = indicatorColor
            stateImage.isHidden = false
        } else {
            stateImage.isHidden = true
        }
        stateView.isHidden = false
    }

    func setupFromObservation(observation: CommonObservation, isFirst: Bool, isLast: Bool) {
        clearCurrentlyDisplayedData()

        loadImage(
            entityImage: observation.images.primaryImage,
            speciesCode: observation.species.knownSpeciesCodeOrNull()?.intValue
        )

        var nameText = "-"

        if let speciesCode = observation.species.knownSpeciesCodeOrNull()?.intValue {
            let species = RiistaGameDatabase.sharedInstance()?.species(byId: speciesCode)
            nameText = RiistaUtils.name(withPreferredLanguage: species?.name)
            itemImage?.tintColor = nil
        }
        else {
            nameText = "-"
        }

        let specimenCount = observation.totalSpecimenAmount?.intValue ?? observation.mooselikeSpecimenAmount
        if (specimenCount > 1) {
            nameText = "\(nameText) (\(specimenCount))"
        }

        speciesLabel.text = nameText

        dateLabel.text = GameLogItemCell.dateFormatter.string(from: observation.pointOfTime.toFoundationDate())
        timeLabel.text = GameLogItemCell.timeFormatter.string(from: observation.pointOfTime.toFoundationDate())

        if (observation.observationType.rawBackendEnumValue != nil) {
            infoLabel.text = observation.observationType.localized(stringProvider: Self.localizationProvider)
            infoLabel.isHidden = false
        } else {
            infoLabel.isHidden = true
        }

        stateLabel.text = nil
        stateImage.tintColor = UIColor.clear
        stateView.isHidden = true

        uploadImage.isHidden = observation.modified == false

        timeLineUp.isHidden = isFirst
        timeLineDown.isHidden = isLast
    }

    func setupFromSrva(srva: CommonSrvaEvent, isFirst: Bool, isLast: Bool) {
        clearCurrentlyDisplayedData()

        loadImage(
            entityImage: srva.images.primaryImage,
            speciesCode: srva.species.knownSpeciesCodeOrNull()?.intValue
        )

        var nameText = "-"

        if let speciesCode = srva.species.knownSpeciesCodeOrNull()?.intValue {
            let species = RiistaGameDatabase.sharedInstance()?.species(byId: speciesCode)
            nameText = RiistaUtils.name(withPreferredLanguage: species?.name)
            itemImage?.tintColor = nil
        }
        else {
            nameText = "SrvaOtherSpeciesShort".localized()

            if let otherSpeciesDescription = srva.otherSpeciesDescription {
                nameText = "\(nameText) - \(otherSpeciesDescription)"
            }

            // If SRVA with unknown species has images, then one of those will be used. If not then unknown icon will be used
            // and tintColor must be set. Otherwise tintColor must be nil.
            if (srva.images.primaryImage != nil) {
                itemImage?.tintColor = nil
            } else {
                itemImage?.tintColor = .black
            }
        }

        if (srva.specimens.count > 1) {
            nameText = "\(nameText) (\(srva.specimens.count))"
        }

        speciesLabel.text = nameText

        dateLabel.text = GameLogItemCell.dateFormatter.string(from: srva.pointOfTime.toFoundationDate())
        timeLabel.text = GameLogItemCell.timeFormatter.string(from: srva.pointOfTime.toFoundationDate())


        if (srva.eventCategory.rawBackendEnumValue != nil) {
            infoLabel.text = srva.eventCategory.localized(stringProvider: Self.localizationProvider)
            infoLabel.isHidden = false
        } else {
            infoLabel.isHidden = true
        }

        setupSrvaState(state: srva.state.rawBackendEnumValue)

        uploadImage.isHidden = srva.modified == false

        timeLineUp.isHidden = isFirst
        timeLineDown.isHidden = isLast
    }

    func setupSrvaState(state: String?) {
        stateLabel.text = nil
        stateImage.tintColor = UIColor.clear

        switch state {
        case SrvaStateApproved:
            stateView.isHidden = false
            stateImage.tintColor = UIColor.applicationColor(RiistaApplicationColorHarvestStatusApproved)
            stateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "SrvaApproved")
        case SrvaStateRejected:
            stateView.isHidden = false
            stateImage.tintColor = UIColor.applicationColor(RiistaApplicationColorHarvestStatusRejected)
            stateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "SrvaRejected")
        default:
            stateView.isHidden = true
        }
    }

    func loadImage(entityImage: EntityImage?, speciesCode: Int?) {
        let imageLoadId = idOf(entityImage: entityImage, speciesCode: speciesCode)
        self.imageLoadedForId = imageLoadId

        ImageUtils.loadEntityImageOrSpecies(
            image: entityImage,
            speciesCode: speciesCode,
            imageView: itemImage,
            options: ImageLoadOptions.aspectFilled(size: itemImage.bounds.size),
            onSuccess: { [weak self] image in
                self?.setDisplayedImage(image, imageLoadId: imageLoadId)
            },
            onFailure: { [weak self] failureReason in
                self?.displayImageLoadFailedIndicator(imageLoadId: imageLoadId)
            }
        )
    }

    func setDisplayedImage(_ image: UIImage, imageLoadId: String?) {
        if (imageLoadedForId != imageLoadId) {
            // cell already recycled, ignore result
            return
        }

        itemImage?.contentMode = .scaleAspectFill
        itemImage?.image = image
    }

    func displayImageLoadFailedIndicator(imageLoadId: String?) {
        if (imageLoadedForId != imageLoadId) {
            // cell already recycled, ignore result
            return
        }

        itemImage?.contentMode = .center
        itemImage?.image = UIImage(named: "missing-image-error")
    }

    private func idOf(entityImage: EntityImage?, speciesCode: Int?) -> String {
        // todo: is event type needed?
        let imageId: String = entityImage?.serverId ??
            entityImage?.localIdentifier ??
            entityImage?.localUrl ?? "-"

        let speciesCodeString = "\(speciesCode ?? -1)"

        return "\(imageId)-\(speciesCodeString)"
    }
}
