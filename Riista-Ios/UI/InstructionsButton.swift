import Foundation
import MaterialComponents.MaterialButtons
import SnapKit

@objc protocol InstructionsButtonDelegate: AnyObject {
    func onInstructionsRequested()
}

// specifically for Instructions right now. Should be quite easy to add necessary
// configuration options for "MaterialHorizontalButton"
@objc class InstructionsButton: UIView {
    // inheriting directly from MDCButton doesn't make it easy to customize title label
    // and icon positioning. It seems that it is easier to simply wrap the button as
    // childview (and not use its label + image) for ripple effect and touch handling.
    // Also use separate label and imageview for displaying the other stuff.
    private let button: MDCButton
    private let questionMarkView: UIImageView
    @objc let titleLabel: UILabel

    @objc weak var delegate: InstructionsButtonDelegate?

    override init(frame: CGRect) {
        self.button = MDCButton()
        self.questionMarkView = UIImageView()
        self.titleLabel = UILabel()

        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(button)
        addSubview(titleLabel)
        addSubview(questionMarkView)

        let questionMarkSize: CGFloat = 32.0
        let margin: CGFloat = 12
        let padding: CGFloat = 10

        questionMarkView.layer.cornerRadius = questionMarkSize / 2
        questionMarkView.backgroundColor = UIColor.applicationColor(Primary)
        questionMarkView.image = UIImage(named: "unknown_white")

        AppTheme.shared.setupTextButtonTheme(button: button)

        button.addTarget(self, action: #selector(onClicked), for: .touchUpInside)
        button.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.left.bottom.right.equalToSuperview()
        }

        questionMarkView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: questionMarkSize, height: questionMarkSize))
            make.centerY.equalTo(button.snp.centerY)
            make.leading.equalToSuperview().offset(margin)
        }

        titleLabel.font = UIFont.appFont(fontSize: .large, fontWeight: .semibold)
        titleLabel.textColor = UIColor.applicationColor(Primary)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(questionMarkView.snp.centerY)
            make.leading.equalTo(questionMarkView.snp.trailing).offset(padding)
            make.trailing.equalToSuperview().offset(-margin)
        }
    }

    @objc private func onClicked() {
        delegate?.onInstructionsRequested()
    }
}
