import Foundation
import SnapKit


/**
 * A view for rows that have two columns. Use together with `TwoColumnStackView`
 */
class TwoColumnRowView: UIView {
    let firstColumnView: UIView
    let secondColumnView: UIView

    init(firstColumnView: UIView, secondColumnView: UIView) {
        self.firstColumnView = firstColumnView
        self.secondColumnView = secondColumnView
        super.init(frame: CGRect.zero)

        addSubview(firstColumnView)
        addSubview(secondColumnView)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported!")
    }
}

class TitleAndValueRow: TwoColumnRowView {
    let titleLabel: UILabel
    let valueLabel: UILabel

    init(titleLabel: UILabel, valueLabel: UILabel) {
        self.titleLabel = titleLabel
        self.valueLabel = valueLabel
        super.init(firstColumnView: titleLabel, secondColumnView: valueLabel)

        constrainLabels()
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    private func constrainLabels() {
        titleLabel.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview()
            make.leading.equalToSuperview()
        }

        valueLabel.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview()

            // leading constrained by the TwoColumnStackView
            make.trailing.lessThanOrEqualToSuperview().priority(999)
            make.firstBaseline.equalTo(titleLabel.snp.firstBaseline)
        }

        self.snp.makeConstraints { make in
            make.bottom.greaterThanOrEqualTo(titleLabel)
            make.bottom.greaterThanOrEqualTo(valueLabel)
        }
    }
}
