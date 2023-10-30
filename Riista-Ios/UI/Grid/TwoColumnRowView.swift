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

        constrainViews()
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported!")
    }

    private func constrainViews() {
        firstColumnView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview()
            make.leading.equalToSuperview()
        }

        secondColumnView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview()

            // leading constrained by the TwoColumnStackView
            make.trailing.lessThanOrEqualToSuperview().priority(999)
            make.firstBaseline.equalTo(secondColumnView.snp.firstBaseline)
        }

        self.snp.makeConstraints { make in
            make.bottom.greaterThanOrEqualTo(firstColumnView)
            make.bottom.greaterThanOrEqualTo(secondColumnView)
        }
    }
}

class TitleAndValueRow: TwoColumnRowView {
    let titleLabel: UILabel
    let valueLabel: UILabel

    init(titleLabel: UILabel, valueLabel: UILabel) {
        self.titleLabel = titleLabel
        self.valueLabel = valueLabel
        super.init(firstColumnView: titleLabel, secondColumnView: valueLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }
}
