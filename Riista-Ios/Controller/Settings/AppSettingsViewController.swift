import Foundation
import DropDown
import SnapKit
import RiistaCommon


class AppSettingsViewController: BaseViewController {
    private static let logger = AppLogger(for: AppSettingsViewController.self, printTimeStamps: false)

    private lazy var settingsView: AppSettingsView = AppSettingsView()
    private var clickCountForExperimentalMode: Int = 0

    private lazy var languageProvider = CurrentLanguageProvider()

    private lazy var synchronizeManuallyButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(named: "refresh_white"),
            style: .plain,
            target: self,
            action: #selector(performManualAppSync)
        )
        return button
    }()

    private lazy var moreMenuButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(named: "more_menu"),
            style: .plain,
            target: self,
            action: #selector(onMoreMenuItemClicked)
        )
        return button
    }()

    override func loadView() {
        // add constraints according to:
        // https://developer.apple.com/library/archive/technotes/tn2154/_index.html
        view = UIView()

        let scrollView = UIScrollView()
        scrollView.backgroundColor = .white
        scrollView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // the layoutMargins we're setting may be less than system minimum layout margins..
        viewRespectsSystemMinimumLayoutMargins = false

        scrollView.addSubview(settingsView)
        settingsView.translatesAutoresizingMaskIntoConstraints = false
        settingsView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview().inset(12)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindToViews()

        self.navigationItem.rightBarButtonItems = [moreMenuButton, synchronizeManuallyButton]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        clickCountForExperimentalMode = 0

        updateUI()
        updateSyncButtons()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onManualSynchronizationPossibleStatusChanged(notification:)),
            name: Notification.Name.ManualSynchronizationPossibleStatusChanged,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }


    private func bindToViews() {
        settingsView.onVersionLabelClicked = {
            self.tryToggleExperimentalMode()
        }

        settingsView.onSyncModeChanged = { synchronizationMode in
            switch (synchronizationMode) {
            case .manual:       AppSync.shared.disableAutomaticSync()
            case .automatic:    AppSync.shared.enableAutomaticSync()
            }

            self.updateSyncButtons()
        }

        settingsView.onLanguageChanged = { language in
            self.languageProvider.setCurrentLanguage(language: language)
            self.updateLocalizedTexts()

            NotificationCenter.default.post(name: .LanguageSelectionUpdated, object: nil)
        }

        settingsView.harvestSettingsButton.onClicked = {
            self.showHarvestSettings()
        }
        settingsView.mapSettingsButton.onClicked = {
            self.showMapSettings()
        }
        settingsView.deleteAccountButton.onClicked = {
            self.showDeleteUserAccount()
        }

    }

    private func showHarvestSettings() {
        let viewController = HarvestSettingsViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func showMapSettings() {
        let viewController = MapSettingsViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func showDeleteUserAccount() {
        // show notification instead if user has already requested to delete account
        let notified = UserAccountUnregisterRequestedViewController.notifyIfUnregistrationRequested(
            navigationController: self.navigationController,
            ignoreCooldown: true
        )

        if (!notified) {
            let viewController = DeleteUserAccountViewController()
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    private func updateUI() {
        settingsView.synchronizationMode = SynchronizationMode.currentValue
        settingsView.language = languageProvider.getCurrentLanguage()

        updateLocalizedTexts()
    }

    private func updateLocalizedTexts() {
        title = "Settings".localized()
        self.settingsView.updateLocalizedTexts()
    }


    // MARK: Experimental

    private func tryToggleExperimentalMode() {
        if (!RemoteConfigurationManager.sharedInstance.experimentalModeAllowed()) {
            Self.logger.d { "Refusing to enable experimental mode, not allowed!" }
            return
        }

        clickCountForExperimentalMode += 1
        Self.logger.d { "Version label clicked! (\(clickCountForExperimentalMode) clicks so far)" }
        if (clickCountForExperimentalMode >= 7) {
            clickCountForExperimentalMode = 0

            FeatureAvailabilityChecker.shared.toggleExperimentalMode()
            settingsView.refreshVersionText()
        }
    }

    // MARK: Synchronization

    private func updateSyncButtons() {
        synchronizeManuallyButton.isHiddenCompat = AppSync.shared.isAutomaticSyncEnabled()
        synchronizeManuallyButton.isEnabled = AppSync.shared.manualSynchronizationPossible

        moreMenuButton.isHiddenCompat = AppSync.shared.isAutomaticSyncEnabled()
        moreMenuButton.isEnabled = AppSync.shared.manualSynchronizationPossible
    }

    @objc private func performManualAppSync() {
        AppSync.shared.synchronizeManually(forceContentReload: false)
    }

    private func performManualSyncAndReloadAllContent() {
        if (!AppSync.shared.manualSynchronizationPossible) {
            // it is possible that something prevented synchronization while menu was being displayed
            // disallowing manual sync
            return
        }

        AppSync.shared.synchronizeManually(forceContentReload: true)
    }

    @objc private func onMoreMenuItemClicked() {
        let dropDown = DropDown()
        dropDown.anchorView = moreMenuButton.plainView
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y: moreMenuButton.plainView.bounds.height)
        dropDown.dataSource = [ "UpdateAllAction".localized() ]
        dropDown.selectionAction = { _, _ in
            self.performManualSyncAndReloadAllContent()
        }

        dropDown.show()
    }

    @objc private func onManualSynchronizationPossibleStatusChanged(notification: Notification) {
        guard let manualSyncPossible = (notification.object as? NSNumber)?.boolValue else {
            return
        }

        synchronizeManuallyButton.isEnabled = manualSyncPossible
        moreMenuButton.isEnabled = manualSyncPossible
    }
}
