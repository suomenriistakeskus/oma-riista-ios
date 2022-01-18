import Foundation
import MaterialComponents
import SnapKit



fileprivate typealias MapTypeAndImage = (RiistaMapType, String)

typealias OnMapTypeChanged = (RiistaMapType) -> Void

/**
 * A view containing the map settings UI.
 *
 * Split from the view controller (MapSettingsViewController) in order to prevent view controller from bloating.
 */
class MapSettingsView: UIStackView {

    private lazy var mapTypeLabel: CaptionView = {
        CaptionView(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapTypeSelect"))
    }()

    private let knownMapTypes: [MapTypeAndImage] = [
        (MmlTopographicMapType, "map_type_mml_topographic.jpg"),
        (MmlBackgroundMapType, "map_type_mml_background.jpg"),
        (MmlAerialMapType, "map_type_mml_aerial.jpg"),
        (GoogleMapType, "map_type_google.jpg"),
    ]

    private lazy var mapTypeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl()

        AppTheme.shared.setupSegmentedController(segmentedController: control)
        if #available(iOS 13.0, *) {
            control.selectedSegmentTintColor = UIColor.applicationColor(Primary)
        } else {
            control.tintColor = UIColor.applicationColor(Primary)
        }

        for (index, (mapType, mapTypeImage)) in knownMapTypes.enumerated() {
            control.insertSegment(with: UIImage(named: mapTypeImage)?.withRenderingMode(.alwaysOriginal),
                                  at: index, animated: false)
        }
        control.addTarget(self, action: #selector(notifyMapTypeChanged), for: .valueChanged)

        // ensure good size
        control.constrainSizeTo(height: AppConstants.UI.ButtonHeightSmall)

        return control
    }()

    var selectedMapType: RiistaMapType {
        get {
            let index = mapTypeSegmentedControl.selectedSegmentIndex
            if (index == UISegmentedControl.noSegment || index < 0 || index >= knownMapTypes.count) {
                return MmlTopographicMapType
            } else {
                let (mapType, _) = knownMapTypes[index]
                return mapType
            }
        }
        set(mapType) {
            let index = knownMapTypes.firstIndex { (knownMapType, _) in
                knownMapType == mapType
            }
            if let index = index {
                mapTypeSegmentedControl.selectedSegmentIndex = index
            }
        }
    }

    /**
     * Will be called when map type changes.
     */
    var onMapTypeChanged: OnMapTypeChanged?

    //MMARK: - Map layers + other settings

    lazy var genericSettingsLabel: CaptionView = {
        CaptionView(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingGeneralTitle"))
    }()

    lazy var showUserLocationToggle: ToggleView = {
        ToggleView(labelText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingShowLocation"),
                   minHeight: AppConstants.UI.DefaultToggleHeight)
    }()

    lazy var invertClubAreaColorsToggle: ToggleView = {
        ToggleView(labelText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingInvertColors"),
                   minHeight: AppConstants.UI.DefaultToggleHeight)
    }()

    lazy var displayStateLandsToggle: ToggleView = {
        ToggleView(labelText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingStateLands"),
                   minHeight: AppConstants.UI.DefaultToggleHeight)
    }()

    // GMA i.e. riistanhoitoyhdistys
    lazy var displayGMABordersToggle: ToggleView = {
        ToggleView(labelText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingRhyBorders"),
                   minHeight: AppConstants.UI.DefaultToggleHeight)
    }()

    lazy var displayGameTrianglesToggle: ToggleView = {
        ToggleView(labelText: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingGameTriangles"),
                   minHeight: AppConstants.UI.DefaultButtonHeight)
    }()

    lazy var offlineSettingsButton: CardButton = {
        CardButton(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingOfflineMaps"))
    }()

    // MARK: - Selected area views

    lazy var selectedAreasLabel: CaptionView = {
        CaptionView(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingSelectedAreas"))
    }()

    lazy var selectedClubAreaView: SelectedMapAreaView = {
        let areaView = SelectedMapAreaView()
        areaView.isHidden = true
        return areaView
    }()

    lazy var selectedSmallGameAreaView: SelectedMapAreaView = {
        let areaView = SelectedMapAreaView()
        areaView.isHidden = true
        return areaView
    }()

    lazy var selectedMooseAreaView: SelectedMapAreaView = {
        let areaView = SelectedMapAreaView()
        areaView.isHidden = true
        return areaView
    }()

    // a custom label to be shown when there are no selected areas
    lazy var noSelectedAreasLabel: UILabel = {
        let label = UILabel()
        label.font = AppTheme.shared.fontForSize(size: AppConstants.Font.LabelMedium)
        label.textColor = UIColor.applicationColor(GreyDark)
        label.textAlignment = .center
        label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingNoSelectedAreas")
        label.isHidden = true

        label.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(60).priority(750)
        }
        return label
    }()


    // MARK: - Add area views

    lazy var addAreaLabel: CaptionView = {
        CaptionView(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapAddArea"))
    }()

    lazy var selectClubAreaButton: CardButton = {
        createSelectAreaButton(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingAddAreaClub"))
    }()

    lazy var selectSmallGameAreaButton: CardButton = {
        createSelectAreaButton(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingAddAreaPienriista"))
    }()

    lazy var selectMooseAreaButton: CardButton = {
        createSelectAreaButton(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingAddAreaMoose"))
    }()

    init() {
        super.init(frame: CGRect.zero)
        setup()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        axis = .vertical
        alignment = .fill
        backgroundColor = .white

        addView(mapTypeLabel, spaceAfter: 8)
        addView(mapTypeSegmentedControl, spaceAfter: 32)

        addView(genericSettingsLabel, spaceAfter: 8)
        addView(showUserLocationToggle)
        addSeparator(spaceAround: 4)
        addView(invertClubAreaColorsToggle)
        addSeparator(spaceAround: 4)
        addView(displayStateLandsToggle)
        addSeparator(spaceAround: 4)
        addView(displayGMABordersToggle)
        addSeparator(spaceAround: 4)
        addView(displayGameTrianglesToggle)
        addSeparator(spaceAround: 4)
        addView(offlineSettingsButton, spaceBefore: 8)

        addView(selectedAreasLabel, spaceBefore: 32, spaceAfter: 8)
        addSeparator()
        addView(selectedClubAreaView)
        addView(selectedSmallGameAreaView)
        addView(selectedMooseAreaView)
        addView(noSelectedAreasLabel)

        addView(addAreaLabel, spaceBefore: 20, spaceAfter: 8)
        addView(selectClubAreaButton, spaceAfter: 8)
        addView(selectSmallGameAreaButton, spaceAfter: 8)
        addView(selectMooseAreaButton, spaceAfter: 8)
    }

    @objc func notifyMapTypeChanged() {
        onMapTypeChanged?(selectedMapType)
    }

    private func createSelectAreaButton(title: String) -> CardButton {
        CardButton(title: title).apply { btn in
            btn.reserveSpaceForIcon = true
            btn.trailingIcon = UIImage(named: "ic_pass_white.png")?.withRenderingMode(.alwaysTemplate)
            btn.trailingIconImageView.tintColor = UIColor.applicationColor(Primary)
            btn.trailingIconImageView.isHidden = true
        }
    }
}
