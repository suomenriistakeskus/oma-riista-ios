import Foundation
import MaterialComponents
import RiistaCommon

fileprivate let hideMarkersImage = UIImage(named: "pins_disabled_white")
fileprivate let showMarkersImage = UIImage(named: "pins_white")

/**
 * A view controller for displaying the normal map (i.e. harvests, observations, srvas)
 */
class MapViewController: BaseMapViewController, RiistaTabPage,
                         LogFilterDelegate, LogDelegate,
                         MapMeasureDistanceControlObserver,
                         ListMapEntriesViewControllerListener,
                         ListensViewModelStatusChanges, PointOfInterestFilterViewControllerDelegate {
    typealias ViewModelType = PoisViewModel

    private lazy var markerManager: MapMarkerManager = {
        // delegate map view events to BaseMapViewController
        let markerManager = MapMarkerManager(mapView: mapView, mapViewDelegate: self)
        markerManager.markerClickHandler = markerClickHandler
        return markerManager
    }()

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
            guard case .objectId(let observationId) = markerItemId else {
                print("markerItemId didn't specify NSManagedObjectId (observation)")
                return false
            }

            self?.onObservationClicked(observationId: observationId)
            return true
        }
        clickHandler.onSrvaMarkerClicked = { [weak self] markerItemId in
            guard case .objectId(let srvaId) = markerItemId else {
                print("markerItemId didn't specify NSManagedObjectId (srva)")
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
        view.enablePointsOfInterest = true
        view.delegate = self
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

    private let harvestControllerHolder = HarvestControllerHolder();
    private let observationsControllerHolder = ObservationControllerHolder(onlyWithImages: false)
    private let srvaControllerHolder = SrvaControllerHolder(onlyWithImages: false)

    private lazy var poiControllerHolder: ControllerHolder<PoisViewModel, PoiController, MapViewController> = {
        let controller = PoiController(
            poiContext: RiistaSDK.shared.poiContext,
            externalId: RiistaSettings.activeClubAreaMapId(),
            initialFilter: PoiFilter(poiFilterType: PoiFilter.PoiFilterType.all)
        )

        return ControllerHolder(controller: controller, listener: self)
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

        tabBarItem.title = "Map".localized()
        navigationItem.title = "" // no nav bar title
        navigationItem.leftBarButtonItem = toggleMarkersBarButton

        loadPointsOfInterestWhenViewAppears()

        LogItemService.shared().logDelegate = self

        updateToggleMarkersButton()
        updateTopFilter()
        refreshMarkers()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshAfterManagedObjectContextChange),
                                               name: NSNotification.Name.ManagedObjectContextChanged,
                                               object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        poiControllerHolder.onViewWillDisappear()
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

    private func updateTopFilter() {
        let sharedService = LogItemService.shared()
        filterView.updateTexts()
        // only update filterview data (and override e.g. point-of-interest selection) if
        // changes have been made elsewhere
        if (sharedService.selectedLogTypeUpdateTimeStamp > filterView.filteredTypeUpdateTimeStamp) {
            filterView.logType = sharedService.selectedLogType
            filterView.seasonStartYear = sharedService.selectedSeasonStart
        }
        filterView.setupUserRelatedData()

        filterView.refreshFilteredSpecies(
            selectedCategory: sharedService.selectedCategory ?? -1,
            selectedSpecies: sharedService.selectedSpecies
        )
    }

    private func onToggleMarkerVisibility() {
        let showPins = filterView.isHidden

        UIView.animate(
            withDuration: AppConstants.Animations.durationShort,
            animations: { [weak self] in
                self?.filterView.isHidden = !showPins
            }
        ) { [weak self] _ in
            self?.updateToggleMarkersButton()
            self?.refreshMarkers()
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
        refreshMarkers()
        filterView.setupUserRelatedData()
    }

    private func refreshMarkers() {
        if (filterView.isHidden) {
            markerManager.removeAllMarkers()
            updatePointOfInterestFilterVisiblity()
            return
        }

        if (filterView.filteredType == .pointsOfInterest) {
            showPointsOfInterestOrIndicateMissingAreaId()
        } else {
            pointOfInterestFilterView.isHidden = true

            switch (LogItemService.shared().selectedLogType) {
            case RiistaEntryTypeHarvest:
                createHarvestMarkers()
            case RiistaEntryTypeObservation:
                createObservationMarkers()
            case RiistaEntryTypeSrva:
                createSrvaMarkers()
            default:
                return
            }
        }
    }

    private func createHarvestMarkers() {
        let fetchController = harvestControllerHolder.getObject()
        fetchController.fetchRequest.predicate = LogItemService.shared().setupHarvestPredicate(onlyWithImage: false)

        markerManager.markerStorage.harvests = fetchItemsForMarkers(fetchController: fetchController)
        markerManager.showOnlyMarkersOfType(markerTypes: [.harvest])
    }

    private func createObservationMarkers() {
        let fetchController = observationsControllerHolder.getObject()
        fetchController.fetchRequest.predicate = LogItemService.shared().setupObservationPredicate(onlyWithImage: false)

        markerManager.markerStorage.observations = fetchItemsForMarkers(fetchController: fetchController)
        markerManager.showOnlyMarkersOfType(markerTypes: [.observation])
    }

    private func createSrvaMarkers() {
        let fetchController = srvaControllerHolder.getObject()
        fetchController.fetchRequest.predicate = LogItemService.shared().setupSrvaPredicate(onlyWithImage: false)

        markerManager.markerStorage.srvas = fetchItemsForMarkers(fetchController: fetchController)
        markerManager.showOnlyMarkersOfType(markerTypes: [.srva])
    }

    private func fetchItemsForMarkers<ItemType>(fetchController: NSFetchedResultsController<ItemType>) -> [ItemType] {
        do {
            try fetchController.performFetch()
        } catch {
            print("Failed to fetch srvas")
            return []
        }

        return fetchController.fetchedObjects ?? []
    }

    // MARK: - Marker click handling

    internal func onHarvestClicked(harvestId: NSManagedObjectID) {
        // harvest can be clicked directly on the map but also from bottomsheet
        // -> ensure bottom sheet is dismissed before navigating forward
        bottomSheetHelper.dismiss() { [weak self] in
            guard let self = self else { return }

            guard let viewController = UIStoryboard(name: "HarvestStoryboard", bundle: nil)
                    .instantiateInitialViewController() as? RiistaLogGameViewController else {
                print("No viewcontroller, cannot display harvest!")
                return
            }

            viewController.eventId = harvestId
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    internal func onObservationClicked(observationId: NSManagedObjectID) {
        // observation can be clicked directly on the map but also from bottomsheet
        // -> ensure bottom sheet is dismissed before navigating forward
        bottomSheetHelper.dismiss() { [weak self] in
            guard let self = self else { return }

            let observationEntry = RiistaGameDatabase.sharedInstance().observationEntry(with: observationId, context: self.moContext)
            if let observation = observationEntry?.toCommonObservation(objectId: observationId) {
                let viewController = ViewObservationViewController(observation: observation)
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }

    internal func onSrvaClicked(srvaId: NSManagedObjectID) {
        // srva can be clicked directly on the map but also from bottomsheet
        // -> ensure bottom sheet is dismissed before navigating forward
        bottomSheetHelper.dismiss() { [weak self] in
            guard let self = self else { return }

            let srvaEntry = RiistaGameDatabase.sharedInstance().srvaEntry(with: srvaId, context: self.moContext)
            if let srvaEvent = srvaEntry?.toSrvaEvent(objectId: srvaId) {
                let viewSrvaViewController = ViewSrvaEventViewController(srvaEvent: srvaEvent)
                self.navigationController?.pushViewController(viewSrvaViewController, animated: true)
            }
        }
    }

    internal func onPointOfInterestClicked(pointOfInterest: PointOfInterest) {
        guard let areaExternalId = poiControllerHolder.controller.externalId else {
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
            harvestControllerHolder: harvestControllerHolder,
            observationsControllerHolder: observationsControllerHolder,
            srvaControllerHolder: srvaControllerHolder,
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
        if let observationId = observationId.localId {
            onObservationClicked(observationId: observationId)
        }
    }

    func onSrvaClicked(srvaId: ItemId) {
        if let srvaId = srvaId.localId {
            onSrvaClicked(srvaId: srvaId)
        }
    }


    // MARK: - LogDelegate

    func refresh() {
        refreshMarkers()
    }


    // MARK: - LogFilterDelegate

    func onFilterTypeSelected(selectedType: LogFilterView.FilteredType, oldType: LogFilterView.FilteredType) {
        switch selectedType {
        case .harvest, .observation, .srva:
            pointOfInterestFilterView.isHidden = true

            if let entryType = selectedType.toRiistaEntryType() {
                LogItemService.shared().setItemType(type: entryType, forceUpdate: selectedType != oldType)
                filterView.seasonStartYear = LogItemService.shared().selectedSeasonStart
            }
        case .pointsOfInterest:
            if (selectedType != oldType) {
                showPointsOfInterestOrIndicateMissingAreaId()
            }
        }
    }

    func onFilterSeasonSelected(seasonStartYear: Int) {
        LogItemService.shared().setSeasonStartYear(year: seasonStartYear)
    }

    func onFilterSpeciesSelected(speciesCodes: [Int]) {
        LogItemService.shared().clearSpeciesCategory()
        LogItemService.shared().setSpeciesList(speciesCodes: speciesCodes)

        filterView.setSelectedSpecies(speciesCodes: speciesCodes)
    }

    func onFilterCategorySelected(categoryCode: Int) {
        let speciesCodes: [Int] = RiistaGameDatabase.sharedInstance()
            .speciesList(withCategoryId: categoryCode)
            .compactMap { speciesItem  in
                if let species = speciesItem as? RiistaSpecies {
                    return species.speciesId
                } else {
                    return nil
                }
            }

        LogItemService.shared().setSpeciesCategory(categoryCode: categoryCode)
        LogItemService.shared().setSpeciesList(speciesCodes: speciesCodes)

        filterView.setSelectedCategory(categoryCode: categoryCode)
    }

    func onFilterPointOfInterestListClicked() {
        let pointOfInterestFilter = poiControllerHolder.controller.getLoadedViewModelOrNull()?.pois?.filter

        let viewController = ListPointsOfInterestViewController(
            areaExternalId: poiControllerHolder.controller.externalId,
            pointOfInterestFilter: pointOfInterestFilter ?? PoiFilter(poiFilterType: .all)
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    func presentSpeciesSelect() {
        guard let navigationController = self.navigationController else { return }

        filterView.presentSpeciesSelect(
            navigationController: navigationController,
            delegate: self
        )
    }


    // MARK: - RiistaTabPage

    func refreshTabItem() {
        tabBarItem.title = "Map".localized()
    }


    // MARK: Points of interest

    private func loadPointsOfInterestWhenViewAppears() {
        poiControllerHolder.controller.externalId = RiistaSettings.activeClubAreaMapId()

        // explicitly don't use poiControllerHolder.onViewWillAppear() as that only loads
        // points of interest if viewmodel has not been updated. Instead do the same thing
        // manually so that we can refresh loaded points of interest (they can be re-fetched
        // in poi list)
        poiControllerHolder.bindToViewModelLoadStatus()
        poiControllerHolder.loadViewModel(refresh: poiControllerHolder.shouldRefreshViewModel)
    }

    private func showPointsOfInterestOrIndicateMissingAreaId() {
        if (poiControllerHolder.controller.externalId == nil) {
            let messageController = MDCAlertController(title: "AlertTitle".localized(),
                                                       message: "PointOfInterestSelectExternalId".localized())
            let okAction = MDCAlertAction(title: "Ok".localized(),
                                          handler: { _ in
                // nop
            })
            messageController.addAction(okAction)

            present(messageController, animated: true, completion: nil)
        } else {
            showPointsOfInterest()
        }
    }

    private func showPointsOfInterest() {
        guard let viewModel = poiControllerHolder.controller.getLoadedViewModelOrNull() else {
            // viewmodel not yet loaded, switch to displaying probably non-existent markers
            showOrRefreshPointOfInterestMarkers()
            updatePointOfInterestFilterVisiblity()
            return
        }

        showPointsOfInterest(viewModel: viewModel)
    }

    private func showPointsOfInterest(viewModel: PoisViewModel) {
        let pointsOfInterest: [PointOfInterest]
        let poiFilterType: PoiFilter.PoiFilterType
        if let poiContainer = viewModel.pois {
            pointsOfInterest = poiContainer.filteredPois
                .flatMap { poiLocationGroup in
                    poiLocationGroup.locations.map { poiLocation in
                        PointOfInterest(
                            group: poiLocationGroup,
                            poiLocation: poiLocation
                        )
                    }
                }

            poiFilterType = poiContainer.filter.poiFilterType
        } else {
            pointsOfInterest = []
            poiFilterType = .all
        }

        markerManager.markerStorage.pointsOfInterest = pointsOfInterest
        showOrRefreshPointOfInterestMarkers()

        pointOfInterestFilterView.update(with: poiFilterType.toFilterType())
        updatePointOfInterestFilterVisiblity()
    }

    private func showOrRefreshPointOfInterestMarkers() {
        if (!markerManager.shownMarkerTypes.contains(.pointOfInterest)) {
            markerManager.showOnlyMarkersOfType(markerTypes: [.pointOfInterest])
        } else {
            markerManager.refreshMarkersOfType(markerTypes: [.pointOfInterest])
        }
    }

    private func updatePointOfInterestFilterVisiblity() {
        let markersNotShown = filterView.isHidden
        let pointsOfInterestsShown = markerManager.shownMarkerTypes.contains(.pointOfInterest)
        let measuring = getMapMeasureControl()?.measureStarted ?? false

        pointOfInterestFilterView.isHidden = markersNotShown || !pointsOfInterestsShown || measuring
    }

    func onWillLoadViewModel(willRefresh: Bool) {
        // nop
    }

    func onLoadViewModelCompleted() {
        // nop
    }

    func onViewModelNotLoaded() {
        // nop
    }

    func onViewModelLoading() {
        // nop
    }

    func onViewModelLoaded(viewModel: PoisViewModel) {
        if (filterView.isHidden || filterView.filteredType != .pointsOfInterest) {
            print("Not updating points of interest on map as they are not yet displayed")
            return
        }
        showPointsOfInterest(viewModel: viewModel)
    }

    func onViewModelLoadFailed() {
        pointOfInterestFilterView.isHidden = true
    }


    // MARK: Point of Interest filter dialog

    private func displayPointOfInterestFilterDialog() {
        let viewModel = poiControllerHolder.controller.getLoadedViewModelOrNull()
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
        poiControllerHolder.controller.eventDispatcher.dispatchPoiFilterChanged(newPoiFilter: newPoiFilter)
    }


    // MARK: MapMeasureDistanceControlObserver

    func onMapMeasureStarted() {
        pointOfInterestFilterView.isHidden = true
    }

    func onMapMeasureEnded() {
        if (filterView.isHidden || filterView.filteredType != .pointsOfInterest) {
            return
        }

        pointOfInterestFilterView.alpha = 0
        pointOfInterestFilterView.isHidden = false
        pointOfInterestFilterView.fadeIn(duration: AppConstants.Animations.durationShort)
    }
}
