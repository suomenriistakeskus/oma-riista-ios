import Foundation
import MaterialComponents
import SnapKit


/**
 * A view containing the offline map settings UI.
 *
 * Split from the view controller (OfflineMapSettingsViewController) in order to prevent view controller from bloating.
 */
class OfflineMapSettingsView: UIStackView {

    private lazy var backgroundMapsLabel: CaptionView = {
        CaptionView(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingLabelBackgroundMaps"))
    }()

    lazy var backgroundMapsCacheStatus: SingleLineValueView = {
        let labelAndValue = SingleLineValueView(mode: .multilineLabel)
        labelAndValue.label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingLabelCacheUtilization")
        labelAndValue.valueLabel.text = "..."
        return labelAndValue
    }()

    lazy var clearBackgroundMapsCache: CardButton = {
        CardButton(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingRemoveBackgroundMaps"))
    }()

    private lazy var mapLayersLabel: CaptionView = {
        CaptionView(text: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingLabelMapLayers"))
    }()

    lazy var mapLayersCacheStatus: SingleLineValueView = {
        let labelAndValue = SingleLineValueView(mode: .multilineLabel)
        labelAndValue.label.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingLabelCacheUtilization")
        labelAndValue.valueLabel.text = "..."
        return labelAndValue
    }()

    lazy var clearMapLayersCache: CardButton = {
        CardButton(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingRemoveMapLayers"))
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

        addView(backgroundMapsLabel, spaceAfter: 8)
        addView(backgroundMapsCacheStatus, spaceAfter: 24)
        addView(clearBackgroundMapsCache, spaceAfter: 32)

        addView(mapLayersLabel, spaceAfter: 8)
        addView(mapLayersCacheStatus, spaceAfter: 24)
        addView(clearMapLayersCache)
    }
}
