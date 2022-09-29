import Foundation
import RiistaCommon

class OccupationTrainingCell: UITableViewCell {
    static let reuseIdentifier = "OccupationTrainingCell"

    private lazy var trainingView: TrainingContentView = TrainingContentView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(training: TrainingViewModel.OccupationTraining) {
        trainingView.updateValues(training: training)
    }

    private func commonInit() {
        contentView.addSubview(trainingView)
        trainingView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview().inset(8)
        }

        let separator = SeparatorView(orientation: .horizontal)
        contentView.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.bottom.equalToSuperview()
        }
    }
}
