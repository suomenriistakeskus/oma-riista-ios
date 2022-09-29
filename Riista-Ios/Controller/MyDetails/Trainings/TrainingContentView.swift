import Foundation
import RiistaCommon

class TrainingContentView: TwoColumnStackView {

    private lazy var dateRow: TitleAndValueRow = createRow(labelKey: "MyDetailsTrainingDate")
    private lazy var placeRow: TitleAndValueRow = createRow(labelKey: "MyDetailsTrainingPlace")
    private lazy var headlineLabel: UILabel = UILabel()

    override init() {
        super.init()
        commonInit()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func updateValues(training: TrainingViewModel.JhtTraining) {
        headlineLabel.text = "\(training.occupationType) (\(training.trainingType))"
        dateRow.valueLabel.text = training.date.toFoundationDate().formatDateOnly()
        placeRow.valueLabel.text = training.location
        placeRow.isHidden = false
    }

    func updateValues(training: TrainingViewModel.OccupationTraining) {
        headlineLabel.text = "\(training.occupationType) (\(training.trainingType))"
        dateRow.valueLabel.text = training.date.toFoundationDate().formatDateOnly()
        placeRow.isHidden = true
    }

    private func commonInit() {
        spacing = 8

        headlineLabel.font = UIFont.appFont(for: .header, fontWeight: .semibold)
        headlineLabel.textColor = UIColor.applicationColor(TextPrimary)
        headlineLabel.lineBreakMode = .byWordWrapping
        headlineLabel.numberOfLines = 2
        addArrangedSubview(headlineLabel)

        addRow(row: dateRow)
        addRow(row: placeRow)
    }

    private func createRow(labelKey: String) -> TitleAndValueRow {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.appFont(for: .label, fontWeight: .regular)
        titleLabel.textColor = UIColor.applicationColor(TextPrimary)
        titleLabel.text = labelKey.localized()
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
