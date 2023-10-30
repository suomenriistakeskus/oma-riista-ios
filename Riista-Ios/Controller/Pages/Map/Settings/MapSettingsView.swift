import Foundation
import MaterialComponents
import SnapKit
import MultiSelectSegmentedControl
import UIKit


fileprivate typealias MapTypeAndImageAndName = (RiistaMapType, String, String)

typealias OnMapTypeChanged = (RiistaMapType) -> Void

/**
 * A view containing the map settings UI.
 *
 * Split from the view controller (MapSettingsViewController) in order to prevent view controller from bloating.
 */
class MapSettingsView: UIStackView {

    private lazy var mapTypeLabel: CaptionView = {
        CaptionView(text: "MapTypeSelect".localized())
    }()

    private let knownMapTypes: [MapTypeAndImageAndName] = [
        (MmlTopographicMapType, "map_type_mml_topographic.jpg", "MapTypeTopographic"),
        (MmlBackgroundMapType, "map_type_mml_background.jpg", "MapTypeBackgound"),
        (MmlAerialMapType, "map_type_mml_aerial.jpg", "MapTypeAerial"),
        (GoogleMapType, "map_type_google.jpg", "MapTypeGoogle"),
    ]

    private lazy var mapTypeSegmentedControl: MultiSelectSegmentedControl = {
        let control = MultiSelectSegmentedControl()
        control.allowsMultipleSelection = false
        control.isVerticalSegmentContents = true
        control.selectedBackgroundColor = UIColor.applicationColor(Primary)
        control.backgroundColor = UIColor.applicationColor(GreyLight)
        control.tintColor = .darkGray

        let font = UIFont.appFont(fontSize: .medium, fontWeight: .regular)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: font], for: .selected)
        control.setTitleTextAttributes([.font: font], for: .normal)

        for (index, (mapType, mapTypeImage, mapTypeName)) in knownMapTypes.enumerated() {
            if let origImage = UIImage(named: mapTypeImage)?.withRenderingMode(.alwaysOriginal) {
                control.insertSegment(contents: [origImage, mapTypeName.localized()])
            }
        }

        control.addTarget(self, action: #selector(notifyMapTypeChanged), for: .valueChanged)

        // ensure good size
        control.constrainSizeTo(height: AppConstants.UI.ButtonHeightSmall + 25)

        return control
    }()

    var selectedMapType: RiistaMapType {
        get {
            let index = mapTypeSegmentedControl.selectedSegmentIndex
            if (index == UISegmentedControl.noSegment || index < 0 || index >= knownMapTypes.count) {
                return MmlTopographicMapType
            } else {
                let (mapType, _, _) = knownMapTypes[index]
                return mapType
            }
        }
        set(mapType) {
            let index = knownMapTypes.firstIndex { (knownMapType, _, _) in
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
        CaptionView(text: "MapSettingGeneralTitle".localized())
    }()

    lazy var showUserLocationToggle: ToggleView = {
        ToggleView(labelText: "MapSettingShowLocation".localized(),
                   minHeight: AppConstants.UI.DefaultToggleHeight)
    }()

    lazy var invertClubAreaColorsToggle: ToggleView = {
        ToggleView(labelText: "MapSettingInvertColors".localized(),
                   minHeight: AppConstants.UI.DefaultToggleHeight)
    }()

    lazy var displayStateLandsToggle: ToggleView = {
        ToggleView(labelText: "MapSettingStateLands".localized(),
                   minHeight: AppConstants.UI.DefaultToggleHeight)
    }()

    // GMA i.e. riistanhoitoyhdistys
    lazy var displayGMABordersToggle: ToggleView = {
        ToggleView(labelText: "MapSettingRhyBorders".localized(),
                   minHeight: AppConstants.UI.DefaultToggleHeight)
    }()

    lazy var displayGameTrianglesToggle: ToggleView = {
        ToggleView(labelText: "MapSettingGameTriangles".localized(),
                   minHeight: AppConstants.UI.DefaultButtonHeight)
    }()

    lazy var displayLeadShotBanToggle: ToggleView = {
        ToggleView(labelText: "MapSettingLeadShotBan".localized(),
                   minHeight: AppConstants.UI.DefaultButtonHeight)
    }()

    lazy var displayMooseRestrictionsToggle: ToggleView = {
        ToggleView(labelText: "MapSettingMooseRestrictions".localized(),
                   minHeight: AppConstants.UI.DefaultButtonHeight)
    }()

    lazy var mooseRestrictionsLink: UITextView = {
        createLabelWithLink(linkText: "MapSettingMooseRestrictionsLink".localized())
    }()

    lazy var displaySmallGameRestrictionsToggle: ToggleView = {
        ToggleView(labelText: "MapSettingSmallGameRestrictions".localized(),
                   minHeight: AppConstants.UI.DefaultButtonHeight)
    }()

    lazy var smallGameRestrictionsLink: UITextView = {
        createLabelWithLink(linkText: "MapSettingSmallGameRestrictionsLink".localized())
    }()

    lazy var displayAviHuntingBanToggle: ToggleView = {
        ToggleView(labelText: "MapSettingAviHuntingBan".localized(),
                   minHeight: AppConstants.UI.DefaultButtonHeight)
    }()

    lazy var aviHuntingBanLink: UITextView = {
        createLabelWithLink(linkText: "MapSettingAviHuntingBanLink".localized())
    }()

    lazy var offlineSettingsButton: CardButton = {
        CardButton(title: "MapSettingOfflineMaps".localized())
    }()

    // MARK: - Selected area views

    lazy var selectedAreasLabel: CaptionView = {
        CaptionView(text: "MapSettingSelectedAreas".localized())
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
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(GreyDark)
        label.textAlignment = .center
        label.text = "MapSettingNoSelectedAreas".localized()
        label.isHidden = true

        label.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(60).priority(750)
        }
        return label
    }()

    func createLabelWithLink(linkText: String) -> UITextView {
        let textView = UnselectableTappableTextView()

        let textColor = UIColor.applicationColor(TextPrimary)!
        let linkColor = UIColor.applicationColor(Primary)!
        let font = UIFont.appFont(for: .label)

        textView.text = linkText
        textView.linkTextAttributes = [.foregroundColor: linkColor]
        textView.textColor = textColor
        textView.isSelectable = true
        textView.isEditable = false
        textView.isUserInteractionEnabled = true
        textView.dataDetectorTypes = .link
        textView.font = font
        textView.textContainer.lineFragmentPadding = 0
        textView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(AppConstants.UI.ButtonHeightSmall).priority(750)
        }
        return textView
    }

    // MARK: - Add area views

    lazy var addAreaLabel: CaptionView = {
        CaptionView(text: "MapAddArea".localized())
    }()

    lazy var selectClubAreaButton: CardButton = {
        createSelectAreaButton(title: "MapSettingAddAreaClub".localized())
    }()

    lazy var selectSmallGameAreaButton: CardButton = {
        createSelectAreaButton(title: "MapSettingAddAreaPienriista".localized())
    }()

    lazy var selectMooseAreaButton: CardButton = {
        createSelectAreaButton(title: "MapSettingAddAreaMoose".localized())
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
        addView(displayLeadShotBanToggle)
        addSeparator(spaceAround: 4)
        addView(displayMooseRestrictionsToggle)
        addView(mooseRestrictionsLink)
        addSeparator(spaceAround: 4)
        addView(displaySmallGameRestrictionsToggle)
        addView(smallGameRestrictionsLink)
        addSeparator(spaceAround: 4)
        addView(displayAviHuntingBanToggle)
        addView(aviHuntingBanLink)
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
