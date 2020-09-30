import UIKit

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

    func setupFromHarvest(harvest: DiaryEntry, isFirst: Bool, isLast: Bool) {
        itemImage.image = nil

        RiistaUtils.loadEventImage(harvest, for: imageView, completion: { image in
            self.itemImage?.image = image
        })

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

    func setupFromObservation(observation: ObservationEntry, isFirst: Bool, isLast: Bool) {
        itemImage.image = nil

        RiistaUtils.loadEventImage(observation, for: imageView, completion: { image in
            self.itemImage?.image = image
        })

        let species = RiistaGameDatabase.sharedInstance()?.species(byId: observation.gameSpeciesCode as! Int)

        let speciesName = RiistaUtils.name(withPreferredLanguage: species?.name)
        if (speciesName != nil) {
            speciesLabel.text = observation.totalSpecimenAmount?.intValue ?? 0 > 1 ?
                "\(speciesName!) (\(observation.totalSpecimenAmount!))" : speciesName
        }
        else {
            speciesLabel.text = "-"
        }

        dateLabel.text = GameLogItemCell.dateFormatter.string(from: observation.pointOfTime!)
        timeLabel.text = GameLogItemCell.timeFormatter.string(from: observation.pointOfTime!)

        infoLabel.text = RiistaBridgingUtils.RiistaMappedString(forkey: observation.observationType!)
        infoLabel.isHidden = false

        stateLabel.text = nil
        stateImage.tintColor = UIColor.clear
        stateView.isHidden = true

        uploadImage.isHidden = observation.sent?.boolValue ?? true

        timeLineUp.isHidden = isFirst
        timeLineDown.isHidden = isLast
    }

    func setupFromSrva(srva: SrvaEntry, isFirst: Bool, isLast: Bool) {
        imageView?.image = nil

        RiistaUtils.loadEventImage(srva, for: imageView, completion: { image in
            self.itemImage?.image = image
        })

        var nameText = "-"

        if let speciesCode = srva.gameSpeciesCode?.intValue {
            imageView?.tintColor = UIColor.clear
            RiistaUtils.loadEventImage(srva, for: imageView, completion: { image in
                self.itemImage?.image = image
            })

            let species = RiistaGameDatabase.sharedInstance()?.species(byId: speciesCode)
            nameText = RiistaUtils.name(withPreferredLanguage: species?.name)
        }
        else {
            imageView?.tintColor = UIColor.black
            imageView?.image = UIImage(named: "unknown_white")

            nameText = RiistaBridgingUtils.RiistaLocalizedString(forkey: "SrvaOtherSpeciesShort")

            if (srva.otherSpeciesDescription != nil) {
                nameText = "\(nameText) - \(srva.otherSpeciesDescription!)"
            }
        }

        if let amount = srva.totalSpecimenAmount?.intValue {
            if (amount > 1) {
                nameText = "\(nameText) (\(amount))"
            }
        }

        speciesLabel.text = nameText

        dateLabel.text = GameLogItemCell.dateFormatter.string(from: srva.pointOfTime!)
        timeLabel.text = GameLogItemCell.timeFormatter.string(from: srva.pointOfTime!)

        infoLabel.text = RiistaBridgingUtils.RiistaMappedString(forkey: srva.eventName!)
        infoLabel.isHidden = false

        setupSrvaState(state: srva.state)

        uploadImage.isHidden = srva.sent?.boolValue ?? true

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
}
