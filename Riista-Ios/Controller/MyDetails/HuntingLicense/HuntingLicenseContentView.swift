import Foundation
import SnapKit


class HuntingLicenseContentView: TwoColumnStackView {

    private lazy var nameRow: TitleAndValueRow = createUserDetailsLabel(labelKey: "MyDetailsName")

    // user details when hunting license is valid
    private lazy var hunterNumberRow: TitleAndValueRow = createUserDetailsLabel(labelKey: "MyDetailsHunterId")
    private lazy var feePaidRow: TitleAndValueRow = createUserDetailsLabel(labelKey: "MyDetailsPayment")
    private lazy var rhyMembershipRow: TitleAndValueRow = createUserDetailsLabel(labelKey: "MyDetailsMembership")

    private lazy var insuranceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "MyDetailsInsurancePolicyText".localized()
        return label
    }()

    private lazy var qrCodeContainer: UIView = {
        let container = UIView()
        container.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.centerX.equalToSuperview()

            let targetSize = calculateTargetQrCodeSizeInPoints()
            make.width.equalTo(targetSize.width)
            make.height.equalTo(targetSize.height)
        }
        return container
    }()

    private lazy var qrCodeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var userDetailsViews: [UIView] = [
        hunterNumberRow, feePaidRow, rhyMembershipRow, insuranceLabel, qrCodeContainer
    ]

    private lazy var huntingBanRow: TitleAndValueRow = createUserDetailsLabel(labelKey: "MyDetailsHuntingBan")

    private lazy var noLicenseView: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = "MyDetailsNoValidLicense".localized()

        return label
    }()

    override init() {
        super.init()
        commonInit()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func updateValues(user: UserInfo) {
        nameRow.valueLabel.text = "\(user.firstName ?? "") \(user.lastName ?? "")"

        if (user.huntingBanStart != nil || user.huntingBanEnd != nil) {
            huntingBanRow.isHidden = false
            noLicenseView.isHidden = true
            userDetailsViews.forEach { $0.isHidden = true }

            huntingBanRow.valueLabel.text = String(format: "%@ - %@",
                                                   user.huntingBanStart?.formatDateOnly() ?? "?",
                                                   user.huntingBanEnd?.formatDateOnly() ?? "?")
        } else if (user.huntingCardValidNow) {
            huntingBanRow.isHidden = true
            noLicenseView.isHidden = true
            userDetailsViews.forEach { $0.isHidden = false }

            hunterNumberRow.valueLabel.text = user.hunterNumber

            feePaidRow.valueLabel.text = String(format: "MyDetailsFeePaidFormat".localized(),
                                                user.huntingCardStart?.formatDateOnly() ?? "",
                                                user.huntingCardEnd?.formatDateOnly() ?? "")

            if let rhy = user.rhy {
                // default to "fi" if language is missing
                let language: String = RiistaSettings.language() ?? "fi"
                // default to Finnish name if no name for language is found
                let rhyName = rhy.name[language] ?? rhy.name["fi"]
                if let rhyName = rhyName {
                    rhyMembershipRow.valueLabel.text =
                        String(format: "%@ (%@)", rhyName as! String, rhy.officialCode)
                }
                else {
                    rhyMembershipRow.valueLabel.text = nil
                }

                // QR code should in theory be always present if hunting license is valid
                // but in practise it may be missing
                if let qrCode = user.qrCode, !qrCode.isEmpty {
                    qrCodeContainer.isHidden = false
                    qrCodeImageView.image = createQrImageFromText(
                        qrString: qrCode,
                        targetSizePoints: calculateTargetQrCodeSizeInPoints()
                    )
                } else {
                    qrCodeContainer.isHidden = true
                    qrCodeImageView.image = nil
                }
            } else {
                rhyMembershipRow.valueLabel.text = ""
            }
        } else {
            huntingBanRow.isHidden = true
            noLicenseView.isHidden = false
            userDetailsViews.forEach { $0.isHidden = true }
        }
    }

    private func createQrImageFromText(qrString: String, targetSizePoints: CGSize) -> UIImage? {
        let stringData = qrString.data(using: String.Encoding.utf8)

        let qrFilter = CIFilter(name: "CIQRCodeGenerator")
        qrFilter?.setValue(stringData, forKey: "inputMessage")
        qrFilter?.setValue("H", forKey: "inputCorrectionLevel")

        guard let qrImage = qrFilter?.outputImage else {
            return nil
        }

        // don't include UIScreen.main.scale here or when creating the actual UIImage
        // - if included here, the image will become too large on the device --> unnecessary scaling in imageview
        // - applying the scale when creating the UIImage causes image to be displayed
        //   differently on device and simulator (smaller on simulator than on device,
        //   assuming imageview.contentMode = .center)
        let scaleX = targetSizePoints.width / qrImage.extent.size.width
        let scaleY = targetSizePoints.height / qrImage.extent.size.height

        return UIImage(
            ciImage: qrImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY)),
            scale: 1, // don't use UIScreen.main.scale
            orientation: .up
        )

    }

    private func calculateTargetQrCodeSizeInPoints() -> CGSize {
        let targetWidth = max(120, UIScreen.main.bounds.width / 2)
        return CGSize(width: targetWidth, height: targetWidth)
    }


    private func commonInit() {
        spacing = 8
        maxFirstColumnWidthMultiplier = 0.4

        addRow(row: nameRow)
        addRow(row: hunterNumberRow)
        addRow(row: feePaidRow)
        addRow(row: rhyMembershipRow)
        addArrangedSubview(insuranceLabel)
        addArrangedSubview(qrCodeContainer)

        addRow(row: huntingBanRow)

        addArrangedSubview(noLicenseView)
    }

    private func createUserDetailsLabel(labelKey: String) -> TitleAndValueRow {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.appFont(for: .label, fontWeight: .regular)
        titleLabel.textColor = UIColor.applicationColor(TextPrimary)
        titleLabel.text = labelKey.localized()
        titleLabel.numberOfLines = 0
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.font = UIFont.appFont(for: .label, fontWeight: .semibold)
        valueLabel.textColor = UIColor.applicationColor(TextPrimary)
        valueLabel.textAlignment = .left
        valueLabel.numberOfLines = 0
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .vertical)

        return TitleAndValueRow(titleLabel: titleLabel, valueLabel: valueLabel)
    }
}
