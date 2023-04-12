import Foundation
import MaterialComponents
import RiistaCommon

fileprivate let hideMarkersImage = UIImage(named: "pins_disabled_white")
fileprivate let showMarkersImage = UIImage(named: "pins_white")

/**
 * A view controller for displaying the normal map (i.e. harvests, observations, srvas)
 */
class MapViewController: BaseMapViewController, RiistaTabPage,
                         LogFilterViewDelegate,
                         EntityDataSourceListener,
                         EntityFilterChangeListener,
                         MapMeasureDistanceControlObserver,
                         ListMapEntriesViewControllerListener,
                         PointOfInterestFilterViewControllerDelegate {
    typealias ViewModelType = PoisViewModel

    private lazy var markerManager: MapMarkerManager = {
        // delegate map view events to BaseMapViewController
        let markerManager = MapMarkerManager(mapView: mapView, mapViewDelegate: self)
        markerManager.markerClickHandler = markerClickHandler
        return markerManager
    }()

    private lazy var mapDataSource: MapDataSource = {
        let dataSource = MapDataSource(markerManager: markerManager)
        dataSource.dataSourceListener = self
        dataSource.addEntityFilterChangeListener(self)
        return dataSource
    }()

    private var pointOfInterestController: PoiController {
        mapDataSource.pointOfInterestDataSource.poiController
    }

    private var pointOfInterestFilter: PoiFilter? {
        pointOfInterestController.getLoadedViewModelOrNull()?.pois?.filter
    }

    private lazy var markerClickHandler: MapMarkerClickHandler = {
        let clickHandler = MapMarkerClickHandler(mapView: mapView)
        clickHandler.onHarvestMarkerClicked = { [weak self] markerItemId in
            guard case .objectId(let harvestId) = markerItemId else {
                print("markerItemId didn't specify NSManagedObjectId (harvest)")
                return false
            }

            self?.onHarvestClicked(harvestId: harvestId)
            return true
        }
        clickHandler.onObservationMarkerClicked = { [weak self] markerItemId in
            guard case .commonLocalId(let observationId) = markerItemId else {
                print("markerItemId didn't specify common local id (observation)")
                return false
            }

            self?.onObservationClicked(observationId: observationId)
            return true
        }
        clickHandler.onSrvaMarkerClicked = { [weak self] markerItemId in
            guard case .commonLocalId(let srvaId) = markerItemId else {
                print("markerItemId didn't specify common local id (srva)")
                return false
            }

            self?.onSrvaClicked(srvaId: srvaId)
            return true
        }
        clickHandler.onPointOfInterstClicked = { [weak self] markerItemId in
            guard case .pointOfInterest(let pointOfInterest) = markerItemId else {
                print("markerItemId didn't specify pointOfInterest")
                return false
            }

            self?.onPointOfInterestClicked(pointOfInterest: pointOfInterest)
            return true
        }
        clickHandler.onDisplayClusterItems = { [weak self] clusteredItems in
            self?.expandCluster(clusteredItems: clusteredItems)
        }
        return clickHandler
    }()

    private lazy var filterView: LogFilterView = {
        let view = LogFilterView()
        view.delegate = self
        view.dataSource = mapDataSource
        view.changeListener = SharedEntityFilterStateUpdater()
        return view
    }()

    // a separate area for filter in order to ease displaying / hiding filters
    private lazy var filterArea: OverlayStackView = {
        let view = OverlayStackView()
        view.alignment = .fill

        view.addArrangedSubview(filterView)
        return view
    }()


    /**
     * A custom view enabling filtering based on diary entry type and accept status.
     */
    private lazy var pointOfInterestFilterView: PointOfInterestFilterView = {
        let view = PointOfInterestFilterView()
        view.button.onClicked = {
            self.displayPointOfInterestFilterDialog()
        }
        view.isHidden = true
        return view
    }()

    /**
     * A helper for displaying bottomsheet when expanding clusters.
     */
    private lazy var bottomSheetHelper: BottomSheetHelper = BottomSheetHelper(hostViewController: self)

    private lazy var toggleMarkersBarButton: UIBarButtonItem = {
        return UIBarButtonItem(customView: toggleMarkersButton)
    }()

    private lazy var toggleMarkersButton: CustomizableMaterialButton = {
        let btn = CustomizableMaterialButton(
            config: CustomizableMaterialButtonConfig { config in
                config.backgroundColor = UIColor.applicationColor(Primary)
                config.titleTextColor = .white
                config.titleTextTransform = { text in
                    text // don't transform
                }
                config.horizontalSpacing = 4
                config.reserveSpaceForLeadingIcon = true
            }
        )
        // shown initially -> indicate possibility for hiding
        btn.leadingIcon = hideMarkersImage
        btn.setTitle("MapHideMarkers".localized(), for: .normal)
        btn.layoutMargins = .zero
        btn.onClicked = { [weak self] in
            self?.onToggleMarkerVisibility()
        }
        if #available(iOS 11.0, *) {
            // nop, lets use autolayout as it is available for navbar starting from ios 11
        } else {
            // use a rough guess for frame size. The frame width will be updated based on text afterwards
            btn.frame = CGRect(x: 0, y: 0, width: 150, height: 32)
        }
        return btn
    }()

    private lazy var appDelegate: RiistaAppDelegate = {
        return UIApplication.shared.delegate as! RiistaAppDelegate
    }()

    private lazy var moContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        context.parent = appDelegate.managedObjectContext
        return context
    }()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        refreshTabItem()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        refreshTabItem()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // force reloading map data since visible data may have been modified
        // - it is possible to e.g. navigate to ViewObservationViewController and edit data there
        //   -> we want to update observation position once we get back here
        mapDataSource.shouldReloadData = true
        SharedEntityFilterState.shared.addListener(mapDataSource)
        filterView.updateTexts()

        tabBarItem.title = "Map".localized()
        navigationItem.title = "" // no nav bar title
        navigationItem.leftBarButtonItem = toggleMarkersBarButton

        loadPointsOfInterestWhenViewAppears()
        showPointsOfInterestOrIndicateMissingAreaId()

        updateToggleMarkersButton()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshAfterManagedObjectContextChange),
                                               name: NSNotification.Name.ManagedObjectContextChanged,
                                               object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        SharedEntityFilterState.shared.removeListener(mapDataSource)
        NotificationCenter.default.removeObserver(self)

        super.viewWillDisappear(animated)
    }


    // MARK: - Setup

    override func createSubviews() {
        super.createSubviews()
        view.addSubview(filterArea)
    }

    override func configureSubviewConstraints() {
        filterArea.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
        }

        super.configureSubviewConstraints()
    }

    override func configureMapControlsOverlayConstraints() {
        mapControlsOverlay.snp.makeConstraints { make in
            // controls may reach both edges
            make.leading.trailing.equalToSuperview()
            make.top.greaterThanOrEqualTo(topLayoutGuide.snp.bottom)
            make.top.greaterThanOrEqualTo(filterArea.snp.bottom)
            make.bottom.equalTo(view.layoutMarginsGuide)
        }
    }

    override func addMapOverlayControls() {
        super.addMapOverlayControls()

        if let measureControl = getMapMeasureControl() {
            measureControl.observer = self
        }

        mapControlsOverlay.bottomCenterControls.addView(pointOfInterestFilterView)
        pointOfInterestFilterView.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
    }

    private func getMapMeasureControl() -> MapMeasureDistanceControl? {
        let control = mapControls.first { $0.type == .measureDistance }
        return control as? MapMeasureDistanceControl
    }


    // MARK: - Marker handling

    private func onToggleMarkerVisibility() {
        let showPins = filterView.isHidden
        mapDataSource.showMarkers = showPins

        UIView.animate(
            withDuration: AppConstants.Animations.durationShort,
            animations: { [weak self] in
                self?.filterView.isHidden = !showPins
            }
        ) { [weak self] _ in
            self?.updateToggleMarkersButton()
            self?.updatePointOfInterestFilterVisiblity()
        }
    }

    private func updateToggleMarkersButton() {
        if (filterView.isHidden) {
            self.toggleMarkersButton.leadingIcon = showMarkersImage
            self.toggleMarkersButton.setTitle("MapShowMarkers".localized(), for: .normal)
        } else {
            self.toggleMarkersButton.leadingIcon = hideMarkersImage
            self.toggleMarkersButton.setTitle("MapHideMarkers".localized(), for: .normal)
        }

        updateToggleMarkersButtonFrameOnIOS10()
    }

    private func updateToggleMarkersButtonFrameOnIOS10() {
        if #available(iOS 11.0, *) {
            // nop, lets use autolayout as it is available for navbar starting from ios 11
            return
        }

        let titleWidth = (toggleMarkersButton.title(for: .normal) ?? "")
            .getPreferredSize(font: toggleMarkersButton.customTitleLabel.font).width

        toggleMarkersButton.updateFrame(width: titleWidth + 40) // 40 = icon + spacings
    }

    @objc private func refreshAfterManagedObjectContextChange() {
        mapDataSource.reloadContent()
    }


    // MARK: - Marker click handling

    internal func onHarvestClicked(harvestId: NSManagedObjectID) {
        // harvest can be clicked directly on the map but also from bottomsheet
        // -> ensure bottom sheet is dismissed before navigating forward
        bottomSheetHelper.dismiss() { [weak self] in
            guard let self = self else { return }

            let diaryEntry = RiistaGameDatabase.sharedInstance().diaryEntry(with: harvestId, context: self.moContext)
            if let harvest = diaryEntry?.toCommonHarvest(objectId: harvestId) {
                let viewController = ViewHarvestViewController(harvest: harvest)
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }

    internal func onObservationClicked(observationId: KotlinLong) {
        // observation can be clicked directly on the map but also from bottomsheet
        // -> ensure bottom sheet is dismissed before navigating forward
        bottomSheetHelper.dismiss() { [weak self] in
            guard let self = self else { return }

            let viewController = ViewObservationViewController(observationId: observationId.int64Value)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    internal func onSrvaClicked(srvaId: KotlinLong) {
        // srva can be clicked directly on the map but also from bottomsheet
        // -> ensure bottom sheet is dismissed before navigating forward
        bottomSheetHelper.dismiss() { [weak self] in
            guard let self = self else { return }

            let viewController = ViewSrvaEventViewController(srvaEventId: srvaId.int64Value)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    internal func onPointOfInterestClicked(pointOfInterest: PointOfInterest) {
        guard let areaExternalId = pointOfInterestController.externalId else {
            print("No area id set, cannot handle poi click")
            return
        }

        // pointOfInterest can be clicked directly on the map but also from bottomsheet
        // -> ensure bottom sheet is dismissed before navigating forward
        bottomSheetHelper.dismiss() { [weak self] in
            guard let self = self else { return }

            let viewController = ViewPointOfInterestViewController(
                areaExternalId: areaExternalId,
                pointOfInterestGroupId: pointOfInterest.group.id,
                pointOfInterestId: pointOfInterest.poiLocation.id
            )

            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    private func expandCluster(clusteredItems: ClusteredMapItems) {
        let viewController = ListMapEntriesViewController(
            clusteredItems: clusteredItems,
            mapDataSource: mapDataSource,
            listener: self
        )

        bottomSheetHelper.display(contentViewController: viewController)
    }


    // MARK: - ListMapEntriesViewController

    func onHarvestClicked(harvestId: ItemId, acceptStatus: AcceptStatus) {
        if let harvestId = harvestId.localId {
            onHarvestClicked(harvestId: harvestId)
        }
    }

    func onObservationClicked(observationId: ItemId, acceptStatus: AcceptStatus) {
        if let observationId = observationId.commonLocalId {
            onObservationClicked(observationId: observationId)
        }
    }

    func onSrvaClicked(srvaId: ItemId) {
        if let srvaId = srvaId.commonLocalId {
            onSrvaClicked(srvaId: srvaId)
        }
    }


    func onFilterPointOfInterestListClicked() {
        let pointOfInterestFilter = pointOfInterestFilter

        let viewController = ListPointsOfInterestViewController(
            areaExternalId: pointOfInterestController.externalId,
            pointOfInterestFilter: pointOfInterestFilter ?? PoiFilter(poiFilterType: .all)
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    func presentSpeciesSelect() {
        guard let navigationController = self.navigationController else { return }

        filterView.presentSpeciesSelect(navigationController: navigationController)
    }


    // MARK: - RiistaTabPage

    func refreshTabItem() {
        tabBarItem.title = "Map".localized()
    }


    // MARK: Points of interest

    private func loadPointsOfInterestWhenViewAppears() {
        pointOfInterestController.externalId = RiistaSettings.activeClubAreaMapId()
        if (mapDataSource.activeDataSource?.filteredEntityType == .pointOfInterest) {
            mapDataSource.pointOfInterestDataSource.controllerHolder.loadViewModelIfNotLoaded(refresh: false)
        }
    }

    private func showPointsOfInterestOrIndicateMissingAreaId() {
        if (mapDataSource.activeDataSource?.filteredEntityType != .pointOfInterest) {
            print("Refusing to display poi dialog / update filter: not displaying points of interest")
            return
        }

        updatePointOfInterestFilterVisiblity()

        if (pointOfInterestController.externalId == nil) {
            let messageController = MDCAlertController(title: "AlertTitle".localized(),
                                                       message: "PointOfInterestSelectExternalId".localized())
            let okAction = MDCAlertAction(title: "Ok".localized(),
                                          handler: { _ in
                // nop
            })
            messageController.addAction(okAction)

            present(messageController, animated: true, completion: nil)
        }
    }

    private func updatePointOfInterestFilterVisiblity() {
        let pointsOfInterestsCannotExist = pointOfInterestController.externalId == nil
        let markersNotShown = filterView.isHidden
        let pointsOfInterestsShown = markerManager.shownMarkerTypes.contains(.pointOfInterest)
        let measuring = getMapMeasureControl()?.measureStarted ?? false

        pointOfInterestFilterView.isHidden = pointsOfInterestsCannotExist || markersNotShown || !pointsOfInterestsShown || measuring
    }


    // MARK: EntityDataSourceListener

    func onDataSourceDataUpdated(for entityType: FilterableEntityType) {
        filterView.refresh()

        updatePointOfInterestFilterVisiblity()

        if (entityType == .pointOfInterest) {
            if let poiFilterType = pointOfInterestFilter?.poiFilterType {
                pointOfInterestFilterView.update(with: poiFilterType.toFilterType())
            }
        }
    }


    // MARK: EntityFilterChangeListener

    func onEntityFilterChanged(change: EntityFilterChange) {
        if (change.hasEntityTypeChanged()) {
            if (change.filter.entityType == .pointOfInterest) {
                showPointsOfInterestOrIndicateMissingAreaId()
            } else {
                pointOfInterestFilterView.isHidden = true
            }
        }
    }


    // MARK: Point of Interest filter dialog

    private func displayPointOfInterestFilterDialog() {
        let viewModel = pointOfInterestController.getLoadedViewModelOrNull()
        if let poiFilter = viewModel?.pois?.filter {
            displayPointOfInterestFilterDialog(filter: poiFilter)
        } else {
            print("No point-of-interest filter (viewmodel not loaded?)")
        }
    }

    private func displayPointOfInterestFilterDialog(filter: PoiFilter) {
        let dialogController = PointOfInterestFilterViewController()
        dialogController.initiallySelectedFilterType = filter.poiFilterType.toFilterType()

        dialogController.delegate = self

        present(dialogController, animated: true, completion:nil)
    }

    func onPointOfInterestFilterChanged(pointOfInterestFilterType: PointOfInterestFilterType) {
        let newPoiFilter = PoiFilter(poiFilterType: pointOfInterestFilterType.toCommonFilterType())
        pointOfInterestController.eventDispatcher.dispatchPoiFilterChanged(newPoiFilter: newPoiFilter)
    }


    // MARK: MapMeasureDistanceControlObserver

    func onMapMeasureStarted() {
        pointOfInterestFilterView.isHidden = true
    }

    func onMapMeasureEnded() {
        if (filterView.isHidden || filterView.filteredType != .pointOfInterest) {
            return
        }

        pointOfInterestFilterView.alpha = 0
        pointOfInterestFilterView.isHidden = false
        pointOfInterestFilterView.fadeIn(duration: AppConstants.Animations.durationShort)
    }
}
