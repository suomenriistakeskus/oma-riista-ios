import Foundation
import DropDown
import SnapKit
import RiistaCommon


class AppSettingsView: UIStackView {
    private static let logger = AppLogger(for: AppSettingsView.self, printTimeStamps: false)


    // MARK: interface to view controller

    var onVersionLabelClicked: OnClicked?

    var synchronizationMode: SynchronizationMode? {
        get {
            let index = synchronizationSegmentedControl.selectedSegmentIndex
            if (index == UISegmentedControl.noSegment) {
                return nil
            }
            return SynchronizationMode.allCases.getOrNil(index: index)
        }
        set(mode) {
            synchronizationSegmentedControl.selectedSegmentIndex = mode?.index ?? UISegmentedControl.noSegment
        }
    }

    var onSyncModeChanged: OnValueChanged<SynchronizationMode>?


    var language: RiistaCommon.Language? {
        get {
            let index = languageSegmentedControl.selectedSegmentIndex
            if (index == UISegmentedControl.noSegment) {
                return nil
            }
            return languages.getOrNil(index: index)?.language
        }
        set(value) {
            let index = languages.firstIndex { selectableLanguage in
                selectableLanguage.language == value
            }
            languageSegmentedControl.selectedSegmentIndex = index ?? UISegmentedControl.noSegment
        }
    }

    var onLanguageChanged: OnValueChanged<RiistaCommon.Language>?


    // MARK: internal views

    private lazy var versionLabel: UILabel = {
        let label = createHeaderLabel(localizationKey: "Version").localizeVersion()

        let clickDetector = UITapGestureRecognizer()
        clickDetector.addTarget(self, action: #selector(handleVersionLabelClick))
        label.addGestureRecognizer(clickDetector)

        label.isUserInteractionEnabled = true

        return label
    }()

    private lazy var synchronizationLabel: UILabel = {
        createHeaderLabel(localizationKey: "Synchronization").localize()
    }()

    private lazy var synchronizationSegmentedControl: UISegmentedControl = {
        let control = createSegmentedControl(onValueChanged: #selector(handleSyncModeChanged))

        for (index, syncMode) in SynchronizationMode.allCases.enumerated() {
            control.insertSegment(withTitle: syncMode.localizedName, at: index, animated: false)
        }

        return control
    }()


    private lazy var languageLabel: UILabel = {
        createHeaderLabel(localizationKey: "Language").localize()
    }()

    private let languages: [SelectableLanguage] = [
        SelectableLanguage(languageName: "Suomi", language: Language.fi),
        SelectableLanguage(languageName: "Svenska", language: Language.sv),
        SelectableLanguage(languageName: "English", language: Language.en),
    ]

    private lazy var languageSegmentedControl: UISegmentedControl = {
        let control = createSegmentedControl(onValueChanged: #selector(handleLanguageChanged))

        for (index, language) in languages.enumerated() {
            // no need to localize language names as thore are already localized
            control.insertSegment(withTitle: language.languageName, at: index, animated: false)
        }

        return control
    }()

    lazy var harvestSettingsButton: CardButton = createCardButton(localizationKey: "HarvestSettings")
    lazy var mapSettingsButton: CardButton = createCardButton(localizationKey: "MapSettings")
    lazy var deleteAccountButton: CardButton = createCardButton(localizationKey: "DeleteUserAccount")

    init() {
        super.init(frame: .zero)
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

        addView(versionLabel, spaceAfter: 24)
        addView(synchronizationLabel, spaceAfter: 8)
        addView(synchronizationSegmentedControl, spaceAfter: 18)
        addView(languageLabel, spaceAfter: 8)
        addView(languageSegmentedControl, spaceAfter: 32)

        let spaceBetween: CGFloat = 12
        addView(harvestSettingsButton, spaceAfter: spaceBetween)
        addView(mapSettingsButton, spaceAfter: spaceBetween)
        addView(deleteAccountButton, spaceAfter: spaceBetween)
    }

    func updateLocalizedTexts() {
        refreshVersionText()

        for (index, syncMode) in SynchronizationMode.allCases.enumerated() {
            synchronizationSegmentedControl.setTitle(syncMode.localizedName, forSegmentAt: index)
        }

        synchronizationLabel.localize()
        languageLabel.localize()
        harvestSettingsButton.localize()
        mapSettingsButton.localize()
        deleteAccountButton.localize()
    }

    func refreshVersionText() {
        versionLabel.localizeVersion()
    }

    private func createHeaderLabel(localizationKey: String) -> UILabel {
        let label = UILabel().configure(
            for: .label,
            fontWeight: .bold
        )
        label.localizationKey = localizationKey
        return label
    }

    private func createSegmentedControl(onValueChanged: Selector) -> UISegmentedControl {
        let control = UISegmentedControl()

        if #available(iOS 13.0, *) {
            control.selectedSegmentTintColor = UIColor.applicationColor(Primary)
            control.tintColor = UIColor.applicationColor(Primary)
        } else {
            control.tintColor = UIColor.applicationColor(Primary)
        }

        let font = UIFont.appFont(fontSize: .medium, fontWeight: .regular)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: font], for: .selected)
        control.setTitleTextAttributes([.font: font], for: .normal)

        control.addTarget(self, action: onValueChanged, for: .valueChanged)

        control.constrainSizeTo(height: AppConstants.UI.ButtonHeightSmall)

        return control
    }

    private func createCardButton(localizationKey: String) -> CardButton {
        CardButton(height: AppConstants.UI.ButtonHeightSmall).apply { btn in
            btn.contentHorizontalAlignment = .leading
            btn.localizationKey = localizationKey
            btn.localize()
        }
    }

    @objc private func handleVersionLabelClick() {
        onVersionLabelClicked?()
    }

    @objc private func handleSyncModeChanged() {
        if let selectedMode = synchronizationMode {
            onSyncModeChanged?(selectedMode)
        } else {
            Self.logger.w { "No selected synchronization mode, cannot notify" }
        }
    }

    @objc private func handleLanguageChanged() {
        if let selectedLanguage = language {
            onLanguageChanged?(selectedLanguage)
        } else {
            Self.logger.w { "No selected language, cannot notify" }
        }
    }
}

fileprivate extension UILabel {
    @discardableResult
    func localizeVersion() -> UILabel {
        self.localizeFormatted { format in
            var appVersion = RiistaSDK.shared.versionInfo.appVersion

            // determine postfix
            if (FeatureAvailabilityChecker.shared.isEnabled(.experimentalMode)) {
                appVersion = appVersion.appending(" (e)")
            }

            return String(format: format, appVersion)
        }
        return self
    }
}

fileprivate extension SynchronizationMode {
    var localizedName: String {
        switch self {
        case .manual:
            return "Manual".localized()
        case .automatic:
            return "Automatic".localized()
        }
    }
}

fileprivate struct SelectableLanguage {
    let languageName: String
    let language: RiistaCommon.Language
}
