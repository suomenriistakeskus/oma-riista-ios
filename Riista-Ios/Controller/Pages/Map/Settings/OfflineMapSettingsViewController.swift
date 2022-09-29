import Foundation
import MaterialComponents
import SnapKit

@objc class OfflineMapSettingsViewController: UIViewController {

    private lazy var settingsContainer: OfflineMapSettingsView = {
        OfflineMapSettingsView()
    }()

    override func loadView() {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .white
        scrollView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        view = scrollView

        if #available(iOS 11.0, *) {
            // the layoutMargins we're setting may be less than system minimum layout margins..
            viewRespectsSystemMinimumLayoutMargins = false
        }

        scrollView.addSubview(settingsContainer)
        settingsContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView.layoutMarginsGuide)
            make.top.equalTo(scrollView).inset(12)
            make.bottom.greaterThanOrEqualTo(scrollView).inset(12)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindToViews()
        updateUI()
    }

    private func bindToViews() {
        settingsContainer.clearBackgroundMapsCache.onClicked = { [weak self] in
            self?.clearBackgroundMapsCache()
        }
        settingsContainer.clearMapLayersCache.onClicked = { [weak self] in
            self?.clearMapLayersCache()
        }
    }

    private func updateUI() {
        title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingOfflineMaps")

        updateDiskCacheUsage(valueLabel: settingsContainer.backgroundMapsCacheStatus.valueLabel,
                             cacheType: .mmlTiles)
        updateDiskCacheUsage(valueLabel: settingsContainer.mapLayersCacheStatus.valueLabel,
                             cacheType: .vectorTiles)
    }

    private func updateDiskCacheUsage(valueLabel: UILabel, cacheType: TileCacheProvider.CacheType) {
        valueLabel.text = "..."

        TileCacheProvider.shared.getDiskCacheUsage(type: cacheType) { bytes in
            if let bytes = bytes {
                let maxCacheSizeMB = TileCacheProvider.shared.getMaxDiskCacheSizeInBytes(type: cacheType).fromBytesToMegaBytes()
                let usedMB = bytes.fromBytesToMegaBytes()

                valueLabel.text =
                    String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "MapSettingCacheUtilizationFormat"),
                           usedMB, maxCacheSizeMB)
            } else {
                valueLabel.text = "-"
            }
        }
    }

    private func clearBackgroundMapsCache() {
        TileCacheProvider.shared.clearDiskCache(type: .mmlTiles) { [weak self] in
            guard let self = self else { return }

            self.updateDiskCacheUsage(
                valueLabel: self.settingsContainer.backgroundMapsCacheStatus.valueLabel,
                cacheType: .mmlTiles
            )
        }
    }

    private func clearMapLayersCache() {
        TileCacheProvider.shared.clearDiskCache(type: .vectorTiles) { [weak self] in
            guard let self = self else { return }

            self.updateDiskCacheUsage(
                valueLabel: self.settingsContainer.mapLayersCacheStatus.valueLabel,
                cacheType: .vectorTiles
            )
        }
    }
}

