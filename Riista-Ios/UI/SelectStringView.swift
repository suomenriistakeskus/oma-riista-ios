import Foundation
import SnapKit

class SelectStringView: UIView {

    var isEnabled: Bool {
        get {
            containerButton.isEnabled
        }
        set(enabled) {
            containerButton.isEnabled = enabled
            updateEnabledIndication()
        }
    }

    var onClicked: OnClicked?

    private lazy var containerButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleClicked), for: .touchUpInside)
        return button
    }()

    let label = LabelView()
    let valueLabel: UILabel = {
        UILabel().configure(
            for: .inputValue,
            textColor: UIColor.applicationColor(GreyDark)
        )
    }()

    private let lineUnderValue: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.applicationColor(TextPrimary)
        return line
    }()

    private let arrowImageView: UIImageView = {
        let arrow = UIImageView()
        arrow.image = UIImage(named: "arrow_forward")?.withRenderingMode(.alwaysTemplate)
        arrow.tintColor = UIColor.applicationColor(Primary)
        return arrow
    }()

    init() {
        super.init(frame: .zero)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(containerButton)
        containerButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerButton.addSubview(label)
        containerButton.addSubview(valueLabel)
        containerButton.addSubview(lineUnderValue)
        containerButton.addSubview(arrowImageView)

        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().inset(4)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(label)
            make.top.equalTo(label.snp.bottom).offset(2)
            make.trailing.equalTo(arrowImageView.snp.leading).inset(2)
            // if the value is empty (i.e. ""), its height will become 0 and thus
            // the line will not be displayed similarly always
            // -> force the height to be larger. This value should also introduce small
            //    padding between label and value.
            make.height.greaterThanOrEqualTo(30).priority(999)
        }

        lineUnderValue.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.equalTo(valueLabel)
            make.trailing.equalTo(arrowImageView)
            make.top.equalTo(valueLabel.snp.bottom)
            make.bottom.equalToSuperview().inset(4)
        }

        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()

            make.height.equalTo(18)
            make.width.equalTo(12)
        }
    }

    @objc private func handleClicked() {
        if let onClicked = onClicked {
            onClicked()
        } else {
            print("No click handler for '\(label.text)' string selection")
        }
    }

    private func updateEnabledIndication() {
        if (isEnabled) {
            arrowImageView.tintColor = UIColor.applicationColor(Primary)
        } else {
            arrowImageView.tintColor = UIColor.applicationColor(GreyMedium)
        }
    }
}
