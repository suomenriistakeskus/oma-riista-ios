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

    func setupFromHarvest(harvest: DiaryEntry, isFirst: Bool, isLast: Bool) {
        clearCurrentlyDisplayedData()

        loadImage(entry: harvest)

        let species = RiistaGameDatabase.sharedInstance()?.species(byId: harvest.gameSpeciesCode as! Int)

        let speciesName = RiistaUtils.name(withPreferredLanguage: species?.name)
        if (speciesName != nil) {
            if (harvest.amount.intValue > 1) {
                speciesLabel.text = "\(speciesName!) (\(harvest.amount!))"
            }
            else {
                speciesLabel.text = speciesName
            }
        }
        else {
            speciesLabel.text = "-"
        }

        dateLabel.text = GameLogItemCell.dateFormatter.string(from: harvest.pointOfTime!)
        timeLabel.text = GameLogItemCell.timeFormatter.string(from: harvest.pointOfTime!)

        infoLabel.text = ""
        infoLabel.isHidden = true

        stateLabel.text = nil
        stateImage.tintColor = UIColor.clear
        stateView.isHidden = true

        setupHarvestState(harvest: harvest, reportState: harvest.harvestReportState, permitState: harvest.stateAcceptedToHarvestPermit)

        uploadImage.isHidden = harvest.sent?.boolValue ?? true

        timeLineUp.isHidden = isFirst
        timeLineDown.isHidden = isLast
    }

    func setupHarvestState(harvest: DiaryEntry, reportState: String?, permitState: String?) {
        if (!setupHarvestReportState(state: reportState)) {
            if (!setupHarvestPermitState(state: permitState)) {
                if (harvest.harvestReportRequired != nil && harvest.harvestReportRequired.boolValue) {
                    stateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "HarvestStateCreateReport")
                    stateImage.tintColor = UIColor.applicationColor(RiistaApplicationColorHarvestStatusCreateReport)

                    stateView.isHidden = false
                }
            }
        }
    }

    func setupHarvestReportState(state: String?) -> Bool {
        switch state {
        case DiaryEntryHarvestStateProposed:
            stateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "HarvestStateProposed")
            stateImage.tintColor = UIColor.applicationColor(RiistaApplicationColorHarvestStatusProposed)

            stateView.isHidden = false

            return true
        case DiaryEntryHarvestStateSentForApproval:
            stateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "HarvestStateSentForApproval")
            stateImage.tintColor = UIColor.applicationColor(RiistaApplicationColorHarvestStatusSentForApproval)

            stateView.isHidden = false

            return true
        case DiaryEntryHarvestStateApproved:
            stateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "HarvestStateApproved")
            stateImage.tintColor = UIColor.applicationColor(RiistaApplicationColorHarvestStatusApproved)

            stateView.isHidden = false

            return true
        case DiaryEntryHarvestStateRejected:
            stateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "HarvestStateRejected")
            stateImage.tintColor = UIColor.applicationColor(RiistaApplicationColorHarvestStatusRejected)

            stateView.isHidden = false

            return true
        default:
            stateView.isHidden = true

            return false;
        }
    }

    func setupHarvestPermitState(state: String?) -> Bool {
        switch state {
        case DiaryEntryHarvestPermitProposed:
            stateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "HarvestPermitStateProposed")
            stateImage.tintColor = UIColor.applicationColor(RiistaApplicationColorHarvestPermitStatusProposed)

            stateView.isHidden = false

            return true
        case DiaryEntryHarvestPermitAccepted:
            stateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "HarvestPermitStateAccepted")
            stateImage.tintColor = UIColor.applicationColor(RiistaApplicationColorHarvestPermitStatusAccepted)

            stateView.isHidden = false

            return true
        case DiaryEntryHarvestPermitRejected:
            stateLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "HarvestPermitStateRejected")
            stateImage.tintColor = UIColor.applicationColor(RiistaApplicationColorHarvestPermitStatusRejected)

            stateView.isHidden = false

            return true
        default:
            stateView.isHidden = true

            return false
        }
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

        if let observationType = observation.observationType.rawBackendEnumValue {
            infoLabel.text = RiistaBridgingUtils.RiistaMappedString(forkey: observationType)
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

        if let eventCategory = srva.eventCategory.rawBackendEnumValue {
            infoLabel.text = RiistaBridgingUtils.RiistaMappedString(forkey: eventCategory)
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

    func loadImage(entry: DiaryEntryBase) {
        self.imageLoadedForId = idOf(entry: entry)

        ImageUtils.loadEventImage(
            entry, for: itemImage,
            options: ImageLoadOptions.aspectFilled(size: itemImage.bounds.size),
            onSuccess: { [weak self, weak entry] image in
                self?.setDisplayedImage(image, entry: entry)
            },
            onFailure: { [weak self, weak entry] failureReason in
                self?.displayImageLoadFailedIndicator(entry: entry)
            }
        )
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

    func setDisplayedImage(_ image: UIImage, entry: DiaryEntryBase?) {
        guard let entry = entry else { return }

        setDisplayedImage(image, imageLoadId: idOf(entry: entry))
    }

    func setDisplayedImage(_ image: UIImage, imageLoadId: String?) {
        if (imageLoadedForId != imageLoadId) {
            // cell already recycled, ignore result
            return
        }

        itemImage?.contentMode = .scaleAspectFill
        itemImage?.image = image
    }

    func displayImageLoadFailedIndicator(entry: DiaryEntryBase?) {
        guard let entry = entry else { return }

        displayImageLoadFailedIndicator(imageLoadId: idOf(entry: entry))
    }

    func displayImageLoadFailedIndicator(imageLoadId: String?) {
        if (imageLoadedForId != imageLoadId) {
            // cell already recycled, ignore result
            return
        }

        itemImage?.contentMode = .center
        itemImage?.image = UIImage(named: "missing-image-error")
    }

    private func idOf(entry: DiaryEntryBase) -> String? {
        return entry.objectID.uriRepresentation().absoluteString
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
