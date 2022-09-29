import Foundation
import GoogleMaps
import MaterialComponents
import SnapKit

fileprivate let ScaleLineLength: CGFloat = 90

fileprivate struct EdgeControlsConfig {
    struct Toggle {
        static let widthVisible: CGFloat = AppConstants.UI.DefaultButtonHeight
        static let widthHidden: CGFloat = AppConstants.UI.DefaultButtonHeight - 10
    }
    struct ButtonControls {
        static let width: CGFloat = AppConstants.UI.DefaultButtonHeight - 6
        static let trailingOffsetVisible: CGFloat = 0
        static let trailingOffsetHidden: CGFloat = width
    }
}

/**
 * A container for map controls to be displayed over map.
 */
class MapControlsOverlayView: OverlayView {

    // MARK: Edge Controls

    private lazy var edgeControlsToggle: CardButton = {
        let view = CardButton()
        view.shapeGenerator = AppTheme.shared.leftRoundedTopCutBottomShapegenerator()
        view.button.setImage(UIImage(named: "menu_expand"), for: .normal)
        view.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight)
        }
        view.onClicked = { [weak self] in
            self?.toggleEdgeControlsVisibility()
        }
        return view
    }()

    private lazy var edgeControlsContainer: MDCCard = {
        let view = MDCCard()
        view.shapeGenerator = AppTheme.shared.bottomLeftRoundedShapegenerator()
        return view
    }()

    /**
     * A view that will be constrain the bottom of edge controls. Allows constraining edge
     * controls above of the bottom right labels and optionally above of the bottom center controls.
     */
    private lazy var edgeControlsBottomConstraintView: UIView = UIView()

    /**
     * A width constraint for bottom center controls. Together with `edgeControlsBottomConstraintView`
     * allows constraining edge controls either above of the bottom right labels or also above of
     * bottom center controls
     */
    private var bottomCenterControlsWidthConstraint: Constraint?

    // Used to 'push' edge controls out of the screen
    private var edgeControlsContainerTrailingConstraint: Constraint?

    // holds the actual buttons
    private lazy var edgeControlsButtons: UIStackView = {
        return UIStackView().apply { view in
            view.axis = .vertical
            view.alignment = .fill
            // separators are atteched to control buttons and thus we can use .fillEqually
            // - if separators also were arrangedSubviews the buttons would be limited
            //   to separator height..
            view.distribution = .fillEqually
        }
    }()

    /**
     * Are the edge controls hidden. The value should be controlled using setEdgeControlsHidden function.
     */
    private(set) var edgeControlsHidden: Bool = true {
        didSet {
            onEdgeControlsHiddenChanged?(edgeControlsHidden)
        }
    }

    /**
     * A callback which will be called when edge controls visibility changes.
     */
    var onEdgeControlsHiddenChanged: ((_ isHidden: Bool) -> Void)?


    // MARK: Bottom center controls

    /**
     * A stackview for holding custom controls at the bottom of the screen.
     */
    private(set) lazy var bottomCenterControls: OverlayStackView = {
        let view = OverlayStackView()
        view.axis = .vertical
        view.spacing = 12
        view.alignment = .center

        // workaround for animations issue:
        // - without this view the bottom center controls animations were animated
        //   to/from bottom left corner of the screen. If an empty UIView is added
        //   the animations are towards bottom of the screen.
        view.addArrangedSubview(UIView())
        return view
    }()


    // MARK: Bottom right UI elements

    /**
     * A stack view holding copyright, map scale line and map scale label.
     */
    private lazy var bottomRightStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .trailing
        stackView.isUserInteractionEnabled = false

        // prevent compressing these in case there are lots of buttons
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        return stackView
    }()

    lazy var copyrightLabel: UILabel = {
        let label = UILabel().configure(
            fontSize: .tiny,
            textColor: UIColor.applicationColor(GreyDark)
        )
        label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapCopyrightMml")
        label.isHidden = true // hidden by default. Needs to be shown if MML maps are displayed.
        return label
    }()

    var copyrightVisible: Bool {
        get {
            !copyrightLabel.isHidden
        }
        set(visible) {
            copyrightLabel.isHidden = !visible
        }
    }

    private lazy var mapScaleLine: UIView = {
        let scaleView = UIView()
        scaleView.backgroundColor = .black
        scaleView.snp.makeConstraints { make in
            make.height.equalTo(5)
            make.width.equalTo(ScaleLineLength)
        }
        return scaleView
    }()

    private lazy var mapScaleLabel: MapLabel = {
        let label = MapLabel()
        // initialize the label with an empty text so that it gets displayed
        // before scale has been drawn and actual label value gets determined
        // - without this the other elements constrained to bottomRightArea will possibly jump
        label.text = " "
        label.textAlignment = .right
        // ensure it also takes the same space as mapScaleLine
        label.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(ScaleLineLength)
        }
        return label
    }()

    var mapScaleVisible: Bool {
        get {
            !mapScaleLine.isHidden
        }
        set(visible) {
            mapScaleLine.isHidden = !visible
            mapScaleLabel.isHidden = !visible
        }
    }

    // MARK: Constructors

    init() {
        super.init(frame: CGRect.zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }


    // MARK: Public API

    func setMapType(type: RiistaMapType) {
        if (type == GoogleMapType) {
            copyrightVisible = false
        } else {
            copyrightVisible = true
        }
    }

    func updateMapScaleLabelText(mapView: GMSMapView) {
        let scaleLengthInMeters = calculateMapScaleLengthInMeters(mapView: mapView)
        updateMapScaleLabelText(scaleLengthInMeters: scaleLengthInMeters)
    }

    /**
     * Adds a edge control button having the specified image. The given onClicked closure will be called
     * when the button is pressed.
     */
    @discardableResult
    func addEdgeControl(image: UIImage?, onClicked: @escaping OnClicked) -> MaterialButton {
        let controlButton = MaterialButton().apply { btn in
            btn.applyTextTheme(withScheme: AppTheme.shared.cardButtonScheme())
            btn.setImage(image, for: .normal)
            btn.setImageTintColor(UIColor.applicationColor(Primary), for: .normal)
            btn.onClicked = onClicked
            btn.snp.makeConstraints { make in
                make.height.equalTo(AppConstants.UI.DefaultButtonHeight).priority(500)
            }
        }

        let separator = SeparatorView(orientation: .horizontal)
        controlButton.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        edgeControlsButtons.addView(controlButton)

        return controlButton
    }

    func setEdgeControlsHidden(isHidden: Bool, animateChange: Bool) {
        edgeControlsHidden = isHidden
        updateEdgeControlsVisibility(animate: animateChange)
    }

    /**
     * Constrains the edge controls so that they appear above of the bottom center controls
     */
    func constrainEdgeControlsAboveOfBottomCenterControls() {
        edgeControlsBottomConstraintView.snp.makeConstraints { make in
            make.bottom
                .lessThanOrEqualTo(bottomCenterControls.snp.top)
                // no offset as bottom center controls has internal spacing (+ internal view)
                .priority(1000)
                .labeled("edge controls above of bottom center controls")
        }
        bottomCenterControlsWidthConstraint?.update(offset: -24)
    }


    // MARK: Private Implementations - map scale

    private func calculateMapScaleLengthInMeters(mapView: GMSMapView) -> CLLocationDistance {
        // calculate the scale length as if scale line would be centered on the map
        // - assumes that scale is not wider than the map!
        let centerY = mapView.frame.height / 2
        let startX = mapView.frame.width / 2 - mapScaleLine.frame.width / 2
        let endX = mapView.frame.width / 2 + mapScaleLine.frame.width / 2

        let startLocation = mapView.projection.coordinate(
            for: CGPoint(x: startX, y: centerY)
        ).toLocation()
        let endLocation = mapView.projection.coordinate(
            for: CGPoint(x: endX, y: centerY)
        ).toLocation()

        return endLocation.distance(from: startLocation)
    }

    private func updateMapScaleLabelText(scaleLengthInMeters: CLLocationDistance) {
        mapScaleLabel.text = MapUtils.formatDistance(distanceMeters: scaleLengthInMeters)
    }


    // MARK: Private Implementations - edge controls

    private func toggleEdgeControlsVisibility() {
        edgeControlsHidden = !edgeControlsHidden
        updateEdgeControlsVisibility(animate: true)
    }

    private func updateEdgeControlsVisibility(animate: Bool) {
        if (animate) {
            UIView.animate(withDuration: AppConstants.Animations.durationShort) { [weak self] in
                guard let self = self else { return }

                self.applyEdgeControlsVisibility(isHidden: self.edgeControlsHidden)
            }
        } else {
            applyEdgeControlsVisibility(isHidden: edgeControlsHidden)
        }
    }

    private func applyEdgeControlsVisibility(isHidden: Bool) {
        let targetAngle: CGFloat = isHidden ? 0 : .pi
        edgeControlsToggle.button.imageView?.layer.transform = CATransform3DMakeRotation(targetAngle, 0, 1, 0)

        edgeControlsToggle.snp.updateConstraints { make in
            createEdgeControlsToggleWidthConstraint(make: make, isHidden: isHidden)
        }
        updateEdgeControlsContainerTrailingConstraint(isHidden: isHidden)

        layoutIfNeeded()
    }

    private func createEdgeControlsToggleWidthConstraint(make: ConstraintMaker, isHidden: Bool) {
        make.width.equalTo(isHidden
            ? EdgeControlsConfig.Toggle.widthHidden
            : EdgeControlsConfig.Toggle.widthVisible
        )
    }

    private func updateEdgeControlsContainerTrailingConstraint(isHidden: Bool) {
        edgeControlsContainerTrailingConstraint?.update(
            offset: isHidden
                ? EdgeControlsConfig.ButtonControls.trailingOffsetHidden
                : EdgeControlsConfig.ButtonControls.trailingOffsetVisible
        )
    }


    // MARK: Private Implementations - view setup

    private func setup() {
        addSubview(edgeControlsToggle)
        addSubview(edgeControlsContainer)
        addSubview(edgeControlsBottomConstraintView)
        addSubview(bottomRightStackView)
        addSubview(bottomCenterControls)

        edgeControlsToggle.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            createEdgeControlsToggleWidthConstraint(make: make, isHidden: edgeControlsHidden)
            make.top
                .greaterThanOrEqualToSuperview()
                .offset(16)
                .priority(1000)
                .labeled("control toggle always on below superview top")
        }

        edgeControlsContainer.addSubview(edgeControlsButtons)
        edgeControlsButtons.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        edgeControlsBottomConstraintView.snp.makeConstraints { make in
            make.bottom
                .lessThanOrEqualTo(bottomRightStackView.snp.top)
                .offset(-16)
                .priority(1000)
                .labeled("edge controls above of labels")
        }

        edgeControlsContainer.snp.makeConstraints { make in
            edgeControlsContainerTrailingConstraint = make.trailing.equalToSuperview().constraint
            make.width.equalTo(EdgeControlsConfig.ButtonControls.width)

            make.centerY
                .equalToSuperview()
                // move downwards slightly in order to take toggle button into account
                .offset(AppConstants.UI.DefaultButtonHeight / 2)
                .priority(500)
                .labeled("prefer centering controls vertically")
            make.bottom
                .lessThanOrEqualTo(edgeControlsBottomConstraintView.snp.top)
                .priority(1000)
                .labeled("controls always above of bottom constraint view")
            make.top.equalTo(edgeControlsToggle.snp.bottom)
                .priority(1000)
                .labeled("controls always below toggle")
        }

        updateEdgeControlsContainerTrailingConstraint(isHidden: edgeControlsHidden)

        bottomRightStackView.snp.makeConstraints { make in
            // superview is expected to take layout margin guide into account
            make.bottom.equalToSuperview().inset(8)
            make.trailing.equalToSuperview().inset(4)
        }

        bottomCenterControls.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            bottomCenterControlsWidthConstraint = make.width
                .equalToSuperview()
                .offset(-2 * (EdgeControlsConfig.Toggle.widthVisible + 2))
                .constraint
            make.bottom.equalTo(bottomRightStackView.snp.top).offset(-8)
        }

        // add in reverse order (bottommost needs to be added as last)
        bottomRightStackView.addArrangedSubview(mapScaleLabel)
        bottomRightStackView.addArrangedSubview(mapScaleLine)
        bottomRightStackView.addArrangedSubview(copyrightLabel)
    }
}
