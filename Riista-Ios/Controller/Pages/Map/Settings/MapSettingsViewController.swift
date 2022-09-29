import Foundation
import MaterialComponents
import SnapKit

@objc class MapSettingsViewController: UIViewController {

    private lazy var settingsContainer: MapSettingsView = {
        MapSettingsView()
    }()

    private let clubAreaManager = RiistaClubAreaMapManager()

    /**
     * Is the view controller visible?
     */
    private var isVisible: Bool = false

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

        if #available(iOS 11.0, *) {
            // the layoutMargins we're setting may be less than system minimum layout margins..
            viewRespectsSystemMinimumLayoutMargins = false
        }

        scrollView.addSubview(settingsContainer)
        settingsContainer.translatesAutoresizingMaskIntoConstraints = false
        settingsContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview().inset(12)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindToViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clubAreaManager.fetchMaps { [weak self] in
            self?.updateSelectedClubAreaMap()
        }
        updateUI()
        isVisible = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
    }

    private func bindToViews() {
        settingsContainer.onMapTypeChanged = { mapType in
            RiistaSettings.setMapTypeSetting(mapType)
        }

        settingsContainer.showUserLocationToggle.onToggled = { isEnabled in
            RiistaSettings.setShowMyMapLocation(isEnabled)
        }
        settingsContainer.invertClubAreaColorsToggle.onToggled = { isEnabled in
            RiistaSettings.setInvertMapColors(isEnabled)
        }
        settingsContainer.displayStateLandsToggle.onToggled = { isEnabled in
            RiistaSettings.setShowStateOwnedLands(isEnabled)
        }
        settingsContainer.displayGMABordersToggle.onToggled = { isEnabled in
            RiistaSettings.setShowRhyBorders(isEnabled)
        }
        settingsContainer.displayGameTrianglesToggle.onToggled = { isEnabled in
            RiistaSettings.setShowGameTriangles(isEnabled)
        }
        settingsContainer.displayMooseRestrictionsToggle.onToggled = { isEnabled in
            RiistaSettings.setShowMooseRestrictions(isEnabled)
        }
        settingsContainer.displaySmallGameRestrictionsToggle.onToggled = { isEnabled in
            RiistaSettings.setShowSmallGameRestrictions(isEnabled)
        }
        settingsContainer.displayAviHuntingBanToggle.onToggled = { isEnabled in
            RiistaSettings.setShowAviHuntingBan(isEnabled)
        }

        settingsContainer.offlineSettingsButton.onClicked = { [weak self] in
            self?.displayOfflineMapSettings()
        }

        settingsContainer.selectedClubAreaView.removeButton.addTarget(
            self, action: #selector(onClearSelectedClubArea), for: .touchUpInside)
        settingsContainer.selectedSmallGameAreaView.removeButton.addTarget(
            self, action: #selector(onClearSelectedSmallGameArea), for: .touchUpInside)
        settingsContainer.selectedMooseAreaView.removeButton.addTarget(
            self, action: #selector(onClearSelectedMooseArea), for: .touchUpInside)

        settingsContainer.selectClubAreaButton.onClicked = { [weak self] in
            self?.displaySelectAreaController(areaType: .Seura)
        }
        settingsContainer.selectSmallGameAreaButton.onClicked = { [weak self] in
            self?.displaySelectAreaController(areaType: .Pienriista)
        }
        settingsContainer.selectMooseAreaButton.onClicked = { [weak self] in
            self?.displaySelectAreaController(areaType: .Moose)
        }
    }

    private func updateUI() {
        title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "Map")

        settingsContainer.selectedMapType = RiistaSettings.mapType()

        settingsContainer.showUserLocationToggle.isToggledOn = RiistaSettings.showMyMapLocation()
        settingsContainer.invertClubAreaColorsToggle.isToggledOn = RiistaSettings.invertMapColors()
        settingsContainer.displayStateLandsToggle.isToggledOn = RiistaSettings.showStateOwnedLands()
        settingsContainer.displayGMABordersToggle.isToggledOn = RiistaSettings.showRhyBorders()
        settingsContainer.displayGameTrianglesToggle.isToggledOn = RiistaSettings.showGameTriangles()
        settingsContainer.displayMooseRestrictionsToggle.isToggledOn = RiistaSettings.showMooseRestrictions()
        settingsContainer.displaySmallGameRestrictionsToggle.isToggledOn = RiistaSettings.showSmallGameRestrictions()
        settingsContainer.displayAviHuntingBanToggle.isToggledOn = RiistaSettings.showAviHuntingBan()

        updateSelectedAreas()
    }

    private func updateSelectedAreas() {
        updateSelectedClubAreaMap()
        updateSelectedSmallGameAreaMap()
        updateSelectedMooseAreaMap()

        updateNoAreasSelected()
    }

    private func updateNoAreasSelected() {
        let atleastOneAreaSelected =
            settingsContainer.selectedClubAreaView.isHidden == false ||
            settingsContainer.selectedSmallGameAreaView.isHidden == false ||
            settingsContainer.selectedMooseAreaView.isHidden == false

        if (atleastOneAreaSelected) {
            settingsContainer.noSelectedAreasLabel.isHidden = true
        } else {
            settingsContainer.noSelectedAreasLabel.isHidden = false
        }
    }

    private func updateSelectedClubAreaMap() {
        let mapAreaView = settingsContainer.selectedClubAreaView
        let selectButton = settingsContainer.selectClubAreaButton
        guard let selectedClubAreaMapId = RiistaSettings.activeClubAreaMapId(),
              let clubArea = clubAreaManager.find(byId: selectedClubAreaMapId) else {
            hideSelectedMapAreaView(view: mapAreaView, button: selectButton)
            return
        }

        showSelectedMapAreaView(view: mapAreaView,
                                button: selectButton,
                                title: RiistaUtils.getLocalizedString(clubArea.club),
                                name: RiistaUtils.getLocalizedString(clubArea.name),
                                areaId: clubArea.externalId)
    }

    private func updateSelectedSmallGameAreaMap() {
        let mapAreaView = settingsContainer.selectedSmallGameAreaView
        let selectButton = settingsContainer.selectSmallGameAreaButton
        guard let selectedMap = RiistaSettings.selectedPienriistaArea() else {
            hideSelectedMapAreaView(view: mapAreaView, button: selectButton)
            return
        }

        showSelectedMapAreaView(view: mapAreaView,
                                button: selectButton,
                                title: selectedMap.getAreaNumberAsString(),
                                name: selectedMap.getAreaName(),
                                areaId: nil)
    }

    private func updateSelectedMooseAreaMap() {
        let mapAreaView = settingsContainer.selectedMooseAreaView
        let selectButton = settingsContainer.selectMooseAreaButton
        guard let selectedMap = RiistaSettings.selectedMooseArea() else {
            hideSelectedMapAreaView(view: mapAreaView, button: selectButton)
            return
        }

        showSelectedMapAreaView(view: mapAreaView,
                                button: selectButton,
                                title: selectedMap.getAreaNumberAsString(),
                                name: selectedMap.getAreaName(),
                                areaId: nil)
    }

    private func showSelectedMapAreaView(view: SelectedMapAreaView, button: CardButton,
                                         title: String, name: String?, areaId: String?) {
        // only animate if already visible (i.e. user is seeing changes)
        settingsContainer.showSubview(view: view, animate: isVisible)

        button.isTrailingIconHidden = false
        view.title = title
        view.name = name
        view.areaId = areaId
    }

    private func hideSelectedMapAreaView(view: SelectedMapAreaView, button: CardButton) {
        // only animate if already visible (i.e. user is seeing changes)
        settingsContainer.hideSubview(view: view, animate: isVisible)

        button.isTrailingIconHidden = true
    }

    private func displayOfflineMapSettings() {
        let controller = OfflineMapSettingsViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

    private func displaySelectAreaController(areaType: AppConstants.AreaType) {
        let storyboard = UIStoryboard(name: "DetailsStoryboard", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "MapAreaListController") as? RiistaMapAreaListViewController else {
            return
        }

        controller.setAreaType(type: areaType)
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func onClearSelectedClubArea() {
        RiistaSettings.setActiveClubAreaMapId(nil)
        updateSelectedClubAreaMap()
        updateNoAreasSelected()
    }

    @objc private func onClearSelectedSmallGameArea() {
        RiistaSettings.setSelectedPienriistaArea(nil)
        updateSelectedSmallGameAreaMap()
        updateNoAreasSelected()
    }

    @objc private func onClearSelectedMooseArea() {
        RiistaSettings.setSelectedMooseArea(nil)
        updateSelectedMooseAreaMap()
        updateNoAreasSelected()
    }
}

