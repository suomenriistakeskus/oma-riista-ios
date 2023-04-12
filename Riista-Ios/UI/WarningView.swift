import Foundation
import MaterialComponents
import UIKit

/**
 * A view capable of displaying exclamation mark, title, message and an action button(s)
 */
class WarningView: UIView {

    // MARK: displayed text + button actions

    var titleText: String? {
        didSet {
            updateTitle()
        }
    }

    var messageText: String? {
        didSet {
            updateMessage()
        }
    }

    var buttonText: String? {
        didSet {
            updateButton()
        }
    }

    var buttonOnClicked: OnClicked? {
        didSet {
            updateButton()
        }
    }


    // MARK: UI elements

    private(set) lazy var scrollableContent: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor.applicationColor(ViewBackground)
        return scrollView
    }()

    private(set) lazy var contentContainerView: UIStackView = {
        let container = UIStackView()
        container.axis = .vertical
        container.distribution = .equalSpacing
        container.alignment = .center
        container.spacing = 16

        return container
    }()

    private(set) lazy var titleLabel: UILabel = UILabel().configure(for: .label, fontWeight: .semibold, textAlignment: .center, numberOfLines: 0)

    private(set) lazy var messageLabel: UILabel = {
        let label = UILabel().configure(for: .label, textAlignment: .center, numberOfLines: 0)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        return label
    }()

    private(set) lazy var buttonContainerView: UIStackView = {
        let container = UIStackView()
        container.axis = .vertical
        container.distribution = .equalSpacing
        container.alignment = .fill
        container.spacing = 12

        return container
    }()

    private(set) lazy var actionButton: MaterialButton = {
        let actionButton = MaterialButton()
        actionButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        actionButton.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight).priority(999)
        }
        actionButton.onClicked = {
            self.onButtonClicked()
        }
        return actionButton
    }()

    init(
        titleText: String?,
        messageText: String?,
        buttonText: String?,
        buttonOnClicked: OnClicked?
    ) {
        self.titleText = titleText
        self.messageText = messageText
        self.buttonText = buttonText
        self.buttonOnClicked = buttonOnClicked

        super.init(frame: .zero)
        setup()
    }

    init() {
        self.titleText = nil
        self.messageText = nil
        self.buttonText = nil
        self.buttonOnClicked = nil
        super.init(frame: .zero)
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("Not implemented")
    }

    private func setup() {
        addSubview(scrollableContent)
        addSubview(buttonContainerView)

        scrollableContent.translatesAutoresizingMaskIntoConstraints = false
        scrollableContent.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(buttonContainerView.snp.top).offset(-12)
        }
        scrollableContent.contentInset.top = 40
        buttonContainerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }

        scrollableContent.addSubview(contentContainerView)

        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollableContent.layoutMarginsGuide)
            make.top.bottom.equalToSuperview().inset(12)
        }

        let exclamationView = UIImageView()
        exclamationView.image = UIImage(named: "exclamation-triangle-green")

        contentContainerView.addView(exclamationView)
        contentContainerView.addView(titleLabel)
        contentContainerView.addView(messageLabel)

        buttonContainerView.addView(actionButton)

        updateTitle()
        updateMessage()
        updateButton()
    }

    private func updateTitle() {
        titleLabel.isHidden = titleText == nil
        titleLabel.text = titleText
    }

    private func updateMessage() {
        messageLabel.isHidden = messageText == nil
        messageLabel.text = messageText
    }

    private func updateButton() {
        actionButton.setTitle(buttonText, for: .normal)
        actionButton.isHidden = (buttonText == nil || buttonOnClicked == nil)
    }

    private func onButtonClicked() {
        buttonOnClicked?()
    }

}
