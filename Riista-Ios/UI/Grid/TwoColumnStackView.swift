import Foundation
import SnapKit


/**
 * A vertical stackview that allows displaying content in two columns that are aligned
 */
class TwoColumnStackView: OverlayStackView {

    // max first column width (of the stack view)
    var maxFirstColumnWidthMultiplier: CGFloat?

    var spacingBetweenColumns: CGFloat = 12

    // A barrier for helping to aling row columns
    private lazy var barrierView: UIView = {
        let barrier = SeparatorView(orientation: .vertical)

        // don't arrange!
        addSubview(barrier)
        // enable to visualize barrier
        /*barrier.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
        }*/

        return barrier
    }()

    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func addRow(row: TwoColumnRowView) {
        addArrangedSubview(row)

        barrierView.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(row.firstColumnView.snp.trailing)
            // comment to align second column to the trailing edge of the screen
            make.leading.equalTo(row.firstColumnView.snp.trailing).priority(999)
        }

        if let maxFirstColumnWidthMultiplier = maxFirstColumnWidthMultiplier {
            row.firstColumnView.snp.makeConstraints { make in
                make.width.equalToSuperview().multipliedBy(maxFirstColumnWidthMultiplier)
            }
        }

        row.secondColumnView.snp.makeConstraints { make in
            make.leading.equalTo(barrierView.snp.trailing).offset(spacingBetweenColumns)
        }
    }

    private func commonInit() {
        axis = .vertical
        alignment = .fill
    }
}

