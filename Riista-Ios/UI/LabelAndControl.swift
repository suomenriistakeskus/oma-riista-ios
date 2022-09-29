import Foundation
import SnapKit


@objc class LabelAndControl: UIView {

    @objc enum LabelAlignment: Int {
        // label is located at the leading side of the control
        case leading

        // label is located at the trailing side of the control
        case trailing
    }

    lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.numberOfLines = 2
        return label
    }()

    var labelText: String {
        get {
            label.text ?? ""
        }
        set(value) {
            label.text = value
        }
    }

    @objc var labelAlignment: LabelAlignment {
        didSet {
            updateLabelAlignment()
        }
    }

    private lazy var spacingView: UIView = {
        let view = UIView()
        view.backgroundColor = nil
        return view
    }()

    private lazy var controlViewContainer: UIView = {
        UIView()
    }()

    private(set) var minHeight: CGFloat

    @objc convenience init(frame: CGRect, labelText: String) {
        self.init(frame: frame, labelText: labelText, minHeight: AppConstants.UI.ButtonHeightSmall)
    }

    @objc init(frame: CGRect, labelText: String, minHeight: CGFloat) {
        self.labelAlignment = .trailing
        self.minHeight = minHeight
        super.init(frame: frame)
        self.labelText = labelText
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func getControlView() -> UIView {
        fatalError("Subclasses are required to implement getControlView()")
    }

    func setup() {
        // reduce the label compression resistance in order to ensure that control
        // never gets out of the screen
        // - it seemed that long enough text can cause e.g. a switch to go out of screen as
        //   label was not wrapped to second line..
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let controlView = getControlView()
        controlViewContainer.addSubview(controlView)
        controlView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(label)
        addSubview(spacingView)
        addSubview(controlViewContainer)

        self.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(minHeight).priority(.medium)
            make.height.greaterThanOrEqualTo(label)
            make.height.greaterThanOrEqualTo(controlViewContainer)
        }

        updateLabelAlignment()
    }

    private func updateLabelAlignment() {
        switch labelAlignment {
        case .leading:
            makeLeadingLabelConstraints()
            break
        case .trailing:
            makeTrailingLabelConstraints()
            break
        }
    }

    private func makeLeadingLabelConstraints() {
        label.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            // for some reasons inset/offset didn't work correctly here
            // -> use a separate spacing view
            make.trailing.equalTo(spacingView.snp.leading)
        }

        spacingView.snp.remakeConstraints { make in
            make.width.equalTo(8)
            make.height.equalToSuperview()
            make.trailing.equalTo(controlViewContainer.snp.leading)
        }

        controlViewContainer.snp.remakeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    private func makeTrailingLabelConstraints() {
        controlViewContainer.snp.remakeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            // for some reasons inset/offset didn't work correctly here
            // -> use a separate spacing view
            make.trailing.equalTo(spacingView.snp.leading)
        }

        spacingView.snp.remakeConstraints { make in
            make.width.equalTo(8)
            make.height.equalToSuperview()
            make.trailing.equalTo(label.snp.leading)
        }

        label.snp.remakeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
        }
    }
}
