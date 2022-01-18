import Foundation
import SnapKit
import RiistaCommon

fileprivate let colorAccepted = UIColor.applicationColor(Primary)!
fileprivate let colorProposed = UIColor.applicationColor(Destructive)!
fileprivate let colorRejected = UIColor.applicationColor(GreyDark)!

class DiaryEntryFieldCell<FieldId : DataFieldId, FieldType : DataField<FieldId>>: TypedDataFieldCell<FieldId, FieldType> {

    private lazy var topLevelContainer: OverlayStackView = {
        let container = OverlayStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 16

        container.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }
        return container
    }()

    override var containerView: UIView {
        topLevelContainer
    }

    var diaryEntryIconImage: UIImage {
        fatalError("Should subclass DiaryEntryFieldCell")
    }

    private lazy var speciesNameLabel: UILabel = createLabel()
    private lazy var amountLabel: UILabel = createLabel()
    private lazy var timeLabel: UILabel = createLabel()
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = diaryEntryIconImage.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = iconTintColor
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        return imageView
    }()

    private(set) var iconTintColor: UIColor = colorAccepted {
        didSet {
            if (iconTintColor != oldValue) {
                iconImageView.tintColor = iconTintColor
            }
        }
    }

    private let speciesNameResolver = SpeciesInformationResolver()

    override func createSubviews(for container: UIView) {
        guard let container = container as? OverlayStackView else {
            fatalError("Expected OverlayStackView as container!")
        }

        // add clickable background directly to contentView
        let background = ClickableCellBackground()
        background.onClicked = { [weak self] in
            self?.onClicked()
        }
        contentView.insertSubview(background, at: 0)
        background.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        container.addView(speciesNameLabel)
        container.addSpacer(size: 16, canExpand: true)
        container.addView(amountLabel)
        container.addView(timeLabel)
        container.addView(iconImageView)
    }

    func onValuesBound(speciesCode: Int32,
                       amount: Int32,
                       pointOfTime: LocalDateTime,
                       acceptStatus: AcceptStatus) {
        let locale = RiistaSettings.locale()

        speciesNameLabel.text = speciesNameResolver.getSpeciesName(speciesCode: speciesCode)?.uppercased(with: locale)
        amountLabel.text = getAmountText(amount: Int(amount)).uppercased(with: locale)
        timeLabel.text = pointOfTime.toFoundationDate().formatTime()
        iconTintColor = getImageTintColor(acceptStatus: acceptStatus)
    }

    func onClicked() {
        print("Cell clicked, should probably handle it")
    }

    private func getImageTintColor(acceptStatus: AcceptStatus) -> UIColor {
        switch acceptStatus {
        case .accepted:     return colorAccepted
        case .proposed:     return colorProposed
        case .rejected:     return colorRejected
        default:
            print("Unexpected acceptStatus \(acceptStatus) observed!")
            return colorAccepted
        }
    }

    func getAmountText(amount: Int) -> String {
        let amountFormat = "AmountFormat".localized()
        return String(format: amountFormat, amount)
    }

    private func createLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: AppConstants.Font.LabelSmall, fontWeight: .semibold)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }
}
