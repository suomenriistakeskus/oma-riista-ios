import Foundation
import MaterialComponents


class CustomizableMaterialButtonConfig {

    var setupTheme: ((CustomizableMaterialButton) -> Void)? = { btn in
        AppTheme.shared.setupTextButtonTheme(button: btn)
    }

    // set nil to use default button bg color
    var backgroundColor: UIColor? = UIColor.applicationColor(ViewBackground)

    var titleFont: UIFont = UIFont.appFont(for: .button)
    var titleTextColor: UIColor = UIColor.applicationColor(TextPrimary)
    var titleTextTransform: (String?) -> String? = { titleText in
        titleText?.uppercased(with: RiistaSettings.locale())
    }
    var titleTextAlignment: NSTextAlignment = .center
    var titleNumberOfLines: Int = 1

    var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)

    // horizontal/vertical spacings between label and icons
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    /**
     * Should space be reserved for a leading/trailing icon? If already reserved, the title won't jump if icon is displayed later.
     */
    var reserveSpaceForLeadingIcon: Bool = false
    var reserveSpaceForTrailingIcon: Bool = false
    var reserveSpaceForTopIcon: Bool = false
    var reserveSpaceForBottomIcon: Bool = false

    // set icon size to nil to use real icon size
    // - if set nil, then space reservation cannot work
    var leadingIconSize: CGSize? = CGSize(width: 18, height: 18)
    var trailingIconSize: CGSize? = CGSize(width: 18, height: 18)
    var topIconSize: CGSize? = CGSize(width: 18, height: 18)
    var bottomIconSize: CGSize? = CGSize(width: 18, height: 18)


    var colorDisabled: UIColor = UIColor.applicationColor(GreyDark)

    init(_ configurator: ((CustomizableMaterialButtonConfig) -> Void)? = nil) {
        configurator?(self)
    }

    func configure(_ configurator: (CustomizableMaterialButtonConfig) -> Void) -> CustomizableMaterialButtonConfig {
        configurator(self)
        return self
    }
}

fileprivate let DEFAULT_BUTTON_CONFIG = CustomizableMaterialButtonConfig()


/**
 * A customizable button providing (almost) full control over leading/trailing icons, title label etc.
 */
class CustomizableMaterialButton: MaterialButton {


    // Leading icon

    /**
     * A convenience property for accessing leading icon image.
     *
     * Prefer using this over accessing leadingIconImageView directly as constraints are updated not
     * updated when directly accessed.
     */
    var leadingIcon: UIImage? {
        get {
            leadingIconImageView.image
        }
        set(image) {
            leadingIconImageView.image = image
            let hidden = image == nil
            if (hidden) {
                isLeadingIconHidden = hidden
            } else {
                leadingIconImageView.isHidden = hidden
                leadingIconImageViewContainer.isHidden = hidden
            }
        }
    }

    /**
     * A convenience property for showing/hiding leading icon.
     *
     * Prefer using this over accessing trailingIconImageView directly as constraints are updated not
     * updated when directly accessed.
     */
    var isLeadingIconHidden: Bool {
        get {
            if (config.reserveSpaceForLeadingIcon) {
                return leadingIconImageView.isHidden
            } else {
                return leadingIconImageViewContainer.isHidden
            }
        }
        set(hidden) {
            if (config.reserveSpaceForLeadingIcon) {
                leadingIconImageView.isHidden = hidden
            } else {
                leadingIconImageViewContainer.isHidden = hidden
            }
        }
    }


    lazy var leadingIconImageView: UIImageView = createImageView()

    private lazy var leadingIconImageViewContainer: OverlayView =
        createImageViewContainer(
            for: leadingIconImageView,
            targetSize: config.leadingIconSize,
            visible: config.reserveSpaceForLeadingIcon
        )


    // Trailing icon

    /**
     * A convenience property for accessing trailing icon image.
     *
     * Prefer using this over accessing topIconImageView directly as otherwise imageview
     * isHidden status is not correctly updated.
     */
    var trailingIcon: UIImage? {
        get {
            trailingIconImageView.image
        }
        set(image) {
            trailingIconImageView.image = image
            let hidden = image == nil
            if (hidden) {
                isTrailingIconHidden = hidden
            } else {
                trailingIconImageView.isHidden = hidden
                trailingIconImageViewContainer.isHidden = hidden
            }
        }
    }

    /**
     * A convenience property for showing/hiding trailing icon.
     *
     * Prefer using this over accessing trailingIconImageView directly as constraints are updated not
     * updated when directly accessed.
     */
    var isTrailingIconHidden: Bool {
        get {
            if (config.reserveSpaceForTrailingIcon) {
                return trailingIconImageView.isHidden
            } else {
                return trailingIconImageViewContainer.isHidden
            }
        }
        set(hidden) {
            if (config.reserveSpaceForTrailingIcon) {
                trailingIconImageView.isHidden = hidden
            } else {
                trailingIconImageViewContainer.isHidden = hidden
            }
        }
    }

    lazy var trailingIconImageView: UIImageView = createImageView()

    private lazy var trailingIconImageViewContainer: OverlayView =
        createImageViewContainer(
            for: trailingIconImageView,
            targetSize: config.trailingIconSize,
            visible: config.reserveSpaceForTrailingIcon
        )


    // MARK: - Top icon

    /**
     * A convenience property for accessing top icon image.
     *
     * Prefer using this over accessing topIconImageView directly as otherwise imageview
     * isHidden status is not correctly updated.
     */
    var topIcon: UIImage? {
        get {
            topIconImageView.image
        }
        set(image) {
            topIconImageView.image = image
            let hidden = image == nil
            if (hidden) {
                isTopIconHidden = hidden
            } else {
                topIconImageView.isHidden = hidden
                topIconImageViewContainer.isHidden = hidden
            }
        }
    }

    /**
     * A convenience property for showing/hiding top icon.
     *
     * Prefer using this over accessing topIconImageView directly as constraints are updated not
     * updated when directly accessed.
     */
    var isTopIconHidden: Bool {
        get {
            if (config.reserveSpaceForTopIcon) {
                return topIconImageView.isHidden
            } else {
                return topIconImageViewContainer.isHidden
            }
        }
        set(hidden) {
            if (config.reserveSpaceForTopIcon) {
                topIconImageView.isHidden = hidden
            } else {
                topIconImageViewContainer.isHidden = hidden
            }
        }
    }

    lazy var topIconImageView: UIImageView = createImageView()

    private lazy var topIconImageViewContainer: OverlayView =
        createImageViewContainer(
            for: topIconImageView,
            targetSize: config.topIconSize,
            visible: config.reserveSpaceForTopIcon
        )


    // MARK - Bottom icon

    /**
     * A convenience property for accessing bottom icon image.
     *
     * Prefer using this over accessing bottomIconImageView directly as otherwise imageview
     * isHidden status is not correctly updated.
     */
    var bottomIcon: UIImage? {
        get {
            bottomIconImageView.image
        }
        set(image) {
            bottomIconImageView.image = image
            let hidden = image == nil
            if (hidden) {
                isBottomIconHidden = hidden
            } else {
                bottomIconImageView.isHidden = hidden
                bottomIconImageViewContainer.isHidden = hidden
            }
        }
    }

    /**
     * A convenience property for showing/hiding bottom icon.
     *
     * Prefer using this over accessing bottomIconImageView directly as constraints are updated not
     * updated when directly accessed.
     */
    var isBottomIconHidden: Bool {
        get {
            if (config.reserveSpaceForBottomIcon) {
                return bottomIconImageView.isHidden
            } else {
                return bottomIconImageViewContainer.isHidden
            }
        }
        set(hidden) {
            if (config.reserveSpaceForBottomIcon) {
                bottomIconImageView.isHidden = hidden
            } else {
                bottomIconImageViewContainer.isHidden = hidden
            }
        }
    }

    lazy var bottomIconImageView: UIImageView = createImageView()

    private lazy var bottomIconImageViewContainer: OverlayView =
        createImageViewContainer(
            for: bottomIconImageView,
            targetSize: config.bottomIconSize,
            visible: config.reserveSpaceForBottomIcon
        )


    // MARK: - custom title

    private(set) lazy var customTitleLabel: UILabel = {
        let label = UILabel()
        label.font = config.titleFont
        label.textColor = config.titleTextColor
        label.numberOfLines = config.titleNumberOfLines
        label.textAlignment = config.titleTextAlignment
        return label
    }()

    override var isEnabled: Bool {
        didSet {
            indicateEnabledStatus(enabled: isEnabled)
        }
    }

    // MARK: - config + init

    /**
     * The configuration that will be used
     */
    private let config: CustomizableMaterialButtonConfig

    init(config: CustomizableMaterialButtonConfig = DEFAULT_BUTTON_CONFIG) {
        self.config = config
        super.init(frame: CGRect.zero)
        setup()
    }

    override init(frame: CGRect) {
        self.config = DEFAULT_BUTTON_CONFIG
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        self.config = DEFAULT_BUTTON_CONFIG
        super.init(coder: coder)
        setup()
    }

    override func title(for state: UIControl.State) -> String? {
        customTitleLabel.text
    }

    override func setTitle(_ title: String?, for state: UIControl.State) {
        customTitleLabel.text = config.titleTextTransform(title)
    }

    override func setImage(_ image: UIImage?, for state: UIControl.State) {
        trailingIcon = image
    }

    private func indicateEnabledStatus(enabled: Bool) {
        let color = enabled ? config.titleTextColor : config.colorDisabled

        [leadingIconImageView, trailingIconImageView, topIconImageView, bottomIconImageView].forEach { imgView in
            imgView.tintColor = color
        }

        customTitleLabel.textColor = color
    }

    private func setup() {
        addTarget(self, action: #selector(onTouchUpInside), for: .touchUpInside)

        if let setupTheme = config.setupTheme {
            setupTheme(self)
        }

        if let configBackgroundColor = config.backgroundColor {
            self.backgroundColor = configBackgroundColor
        }

        let verticalContainer = OverlayStackView()
        verticalContainer.axis = .vertical
        verticalContainer.alignment = .center
        verticalContainer.spacing = config.verticalSpacing

        verticalContainer.addView(topIconImageViewContainer)
        verticalContainer.addView(customTitleLabel)
        verticalContainer.addView(bottomIconImageViewContainer)
        customTitleLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }


        let horizontalContainer = OverlayStackView()
        horizontalContainer.axis = .horizontal
        horizontalContainer.alignment = .center
        horizontalContainer.spacing = config.horizontalSpacing
        addSubview(horizontalContainer)

        horizontalContainer.addView(leadingIconImageViewContainer)
        horizontalContainer.addView(verticalContainer)
        horizontalContainer.addView(trailingIconImageViewContainer)

        horizontalContainer.snp.makeConstraints { make in
            make.edges.equalTo(self.layoutMarginsGuide)
        }
    }

    private func createImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = config.titleTextColor
        return imageView
    }

    private func createImageViewContainer(for imageView: UIImageView,
                                          targetSize: CGSize?,
                                          visible: Bool) -> OverlayView {
        let container = OverlayView()
        container.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // constrain the _container_ size as that allows reserving space for icon
        if let targetSize = targetSize {
            container.snp.makeConstraints { make in
                make.size.equalTo(targetSize)
            }
        }

        container.isHidden = !visible
        return container
    }
}

