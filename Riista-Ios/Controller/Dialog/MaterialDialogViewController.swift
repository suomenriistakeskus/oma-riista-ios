import Foundation
import MaterialComponents

fileprivate let doublePadding: CGFloat = 24

class MaterialDialogViewController: UIViewController {

    /**
     * A top-level stackview for displaying title, contentView and buttons
     */
    private lazy var topLevelContainer: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .fill
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .title)
        label.textColor = UIColor.applicationColor(TextPrimary)
        return label
    }()

    private(set) lazy var buttonArea: UIStackView = {
        let buttons = UIStackView()
        buttons.axis = .horizontal
        buttons.alignment = .fill
        buttons.spacing = 12

        // the top-level container has .fill alignment -> add spacer so that
        // buttons are at the trailing end
        buttons.addSpacer(size: 0, canShrink: false, canExpand: true)
        buttons.addView(cancelButton)
        buttons.addView(okButton)
        return buttons
    }()

    lazy var okButton: MaterialButton = {
        return createDialogButton(localizationKey: "Ok") { [weak self] in
            self?.onOkClicked()
        }
    }()

    lazy var cancelButton: MaterialButton = {
        return createDialogButton(localizationKey: "Cancel") { [weak self] in
            self?.onCancelClicked()
        }
    }()

    /**
     * A view for holding the dialog content.
     */
    private(set) var contentViewContainer = UIView()

    // A transition controller to be used as transitioning delegate
    private let transitionController = MDCDialogTransitionController()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        modalPresentationStyle = .custom
        transitioningDelegate = transitionController
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor.applicationColor(ViewBackground)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .horizontal)


        view.addSubview(topLevelContainer)

        topLevelContainer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        topLevelContainer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        topLevelContainer.setContentHuggingPriority(.required, for: .vertical)
        topLevelContainer.setContentHuggingPriority(.required, for: .horizontal)

        topLevelContainer.addView(titleLabel)

        topLevelContainer.addView(contentViewContainer)

        topLevelContainer.addSpacer(size: 12, canShrink: false, canExpand: true)
        topLevelContainer.addArrangedSubview(buttonArea)

        topLevelContainer.snp.makeConstraints { make in
            // by default the dialogs (from MaterialComponents) will take almost the fullscreen height
            // -> constrain so that topLevelContainer is allowed to take less than that +
            //    set preferredContentSize when constraints have been applied
            make.height.lessThanOrEqualToSuperview().offset(-doublePadding)
            make.width.equalToSuperview().offset(-doublePadding)
            make.center.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        preferredContentSize = CGSize(
            width: topLevelContainer.frame.width + doublePadding,
            height: topLevelContainer.frame.height + doublePadding
        )
    }

    func onOkClicked() {
        dismiss(animated: true, completion: nil)
    }

    func onCancelClicked() {
        dismiss(animated: true, completion: nil)
    }

    func createDialogButton(localizationKey: String, onClicked: @escaping OnClicked) -> MaterialButton {
        let button = MaterialButton()
        button.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: localizationKey), for: .normal)
        button.applyTextTheme(withScheme: AppTheme.shared.outlineButtonScheme())
        button.onClicked = onClicked
        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return button
    }
}
