import Foundation
import MaterialComponents
import SnapKit

import RiistaCommon

class GroupHuntingMapViewController: BaseMapViewController,
                                     ListensViewModelStatusChanges,
                                     GroupHuntingUpdateDiaryFilterViewControllerDelegate,
                                     MapMeasureDistanceControlObserver,
                                     ViewGroupHarvestListener,
                                     ViewGroupObservationListener,
                                     ListGroupDiaryEntriesViewControllerListener {

    typealias ViewModelType = ListDiaryEventsViewModel

    private lazy var filterArea: UIView = {
        let view = UIView()
        view.addSubview(contentNotLoadedLabel)
        contentNotLoadedLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(dateFilter)
        dateFilter.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()

    private lazy var contentNotLoadedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(GreyDark)
        label.textAlignment = .center
        return label
    }()

    private lazy var dateFilter: DateFilterView = {
        let filter = DateFilterView().withSeparatorAtBottom()
        filter.presentingViewController = self

        filter.onStartDateChanged = { [weak self] startDate in
            self?.controllerHolder.controller.eventDispatcher.dispatchFilterStartDateChanged(
                newStartDate: startDate.toLocalDate()
            )
        }
        filter.onEndDateChanged = { [weak self] endDate in
            self?.controllerHolder.controller.eventDispatcher.dispatchFilterEndDateChanged(
                newEndDate: endDate.toLocalDate()
            )
        }

        return filter
    }()

    /**
     * A custom view enabling filtering based on diary entry type and accept status.
     */
    private lazy var diaryFilterView: GroupHuntingDiaryFilterView = {
        let view = GroupHuntingDiaryFilterView()
        view.button.onClicked = {
            self.displayDiaryFilterUpdateDialog()
        }
        return view
    }()

    private let huntingGroupTarget: HuntingGroupTarget

    /**
     * Has the map been centered to the group area after loading group entries?
     */
    var mapCenteredToGroupArea: Bool = false

    /**
     * A MapLayerId for the hunting group area
     */
    var groupAreaLayerId: MapLayerId?

    /**
     * Has the group area layer been configured?
     */
    var groupAreaLayerConfigured: Bool = false


    lazy var controllerHolder: ControllerHolder<ListDiaryEventsViewModel, DiaryController, GroupHuntingMapViewController> = {
        let controller = DiaryController(
            groupHuntingContext: UserSession.shared().groupHuntingContext,
            groupTarget: huntingGroupTarget
        )

        return ControllerHolder(controller: controller, listener: self)
    }()

    private lazy var markerManager: GroupHuntingMarkerManager = {
        // delegate map view events to BaseMapViewController
        let markerManager = GroupHuntingMarkerManager(mapView: mapView, mapViewDelegate: self)
        markerManager.markerClickHandler = markerClickHandler
        return markerManager
    }()

    private lazy var markerClickHandler: MarkerClickHandler<GroupHuntingMarkerItem> = {
        let clickHandler = GroupHuntingMarkerClickHandler(mapView: mapView)
        clickHandler.onHarvestMarkerClicked = { [weak self] harvestId, acceptStatus in
            self?.onHarvestClicked(harvestId: .remote(id: harvestId), acceptStatus: acceptStatus)
            return true
        }
        clickHandler.onObservationMarkerClicked = { [weak self] observationId, acceptStatus in
            self?.onObservationClicked(observationId: .remote(id: observationId), acceptStatus: acceptStatus)
            return true
        }
        clickHandler.onDisplayClusterItems = { [weak self] harvestIds, observationIds in
            self?.expandCluster(harvestIds: harvestIds, observationIds: observationIds)
        }
        return clickHandler
    }()

    /**
     * A helper for displaying bottomsheet when expanding clusters.
     */
    private lazy var bottomSheetHelper: BottomSheetHelper = BottomSheetHelper(hostViewController: self)


    init(huntingGroupTarget: HuntingGroupTarget) {
        self.huntingGroupTarget = huntingGroupTarget
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "GroupHuntingEntriesOnMap")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        controllerHolder.onViewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        controllerHolder.onViewWillDisappear()
    }

    override func createSubviews() {
        super.createSubviews()
        view.addSubview(filterArea)
    }

    override func createNavigationBarItems() -> [UIBarButtonItem] {
        var items = super.createNavigationBarItems()
        let refresh = UIBarButtonItem(image: UIImage(named: "refresh_white"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(onRefreshClicked))
        items.append(refresh)
        return items
    }

    @objc func onRefreshClicked() {
        controllerHolder.loadViewModel(refresh: true)
    }

    override func configureSubviewConstraints() {
        filterArea.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }

        super.configureSubviewConstraints()
    }

    override func configureMapConstraints() {
        mapView.snp.makeConstraints { make in
            // allow to reach bottom edge i.e don't stop at layout guide at bottom..
            make.leading.trailing.bottom.equalToSuperview()

            // ..but always ensure map is below filter area
            make.top.equalTo(filterArea.snp.bottom)
        }
    }

    override func configureMapControlsOverlayConstraints() {
        mapControlsOverlay.snp.makeConstraints { make in
            // controls may reach both edges
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(mapView)
            make.bottom.equalTo(view.layoutMarginsGuide)
        }
    }

    override func addMapOverlayControls() {
        super.addMapOverlayControls()

        if let measureControl = getMapMeasureControl() {
            measureControl.observer = self
        }

        mapControlsOverlay.bottomCenterControls.addView(diaryFilterView)
        diaryFilterView.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
    }

    private func getMapMeasureControl() -> MapMeasureDistanceControl? {
        let control = mapControls.first { $0.type == .measureDistance }
        return control as? MapMeasureDistanceControl
    }

    override func addMapLayers() {
        super.addMapLayers()
        addHuntingGroupAreaLayer()
    }

    private func addHuntingGroupAreaLayer() {
        let layerId = calculateLayerIdForHuntingGroupAreaLayer()
        mapView.addMapLayer(layerId: layerId, areaType: .Seura, zIndex: 10)
        mapView.setMapLayerVisibility(layerId: layerId, visible: false)
        groupAreaLayerId = layerId
    }

    private func calculateLayerIdForHuntingGroupAreaLayer() -> MapLayerId {
        var candidateId: MapLayerId = mapView.maxOverlayLayerId + 100
        while (mapView.hasMapLayer(layerId: candidateId)) {
            candidateId += 1
        }
        return candidateId
    }

    func onWillLoadViewModel(willRefresh: Bool) {
        // nop, indicated upon
    }

    func onLoadViewModelCompleted() {
        // nop
    }

    func onViewModelNotLoaded() {
        dateFilter.alpha = 0
        contentNotLoadedLabel.alpha = 1
        contentNotLoadedLabel.text = ""
        diaryFilterView.isHidden = true
    }

    func onViewModelLoading() {
        dateFilter.alpha = 0
        contentNotLoadedLabel.alpha = 1
        contentNotLoadedLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "GenericLoadingContent")
    }

    func onViewModelLoaded(viewModel: ListDiaryEventsViewModel) {
        if let events = viewModel.events {
            dateFilter.alpha = 1
            diaryFilterView.isHidden = false
            contentNotLoadedLabel.alpha = 0
            contentNotLoadedLabel.text = ""

            centerMapToGroupAreaIfNeeded(huntingGroupArea: events.huntingGroupArea)
            displayGroupArea(huntingGroupArea: events.huntingGroupArea)

            updateDateFilter(events: events)

            markerManager.markerStorage.harvests = events.filteredEvents.harvests
            markerManager.markerStorage.observations = events.filteredEvents.observations

            applyDiaryFilter(diaryFilter: events.diaryFilter)
        } else {
            dateFilter.alpha = 0
            contentNotLoadedLabel.alpha = 1
            contentNotLoadedLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "GroupHuntingNoHarvestsNoObservations")
            diaryFilterView.isHidden = true
        }
    }

    func onViewModelLoadFailed() {
        dateFilter.alpha = 0
        contentNotLoadedLabel.alpha = 1
        contentNotLoadedLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "GenericContentLoadingFailed")
        diaryFilterView.isHidden = true
    }

    private func updateDateFilter(events: DiaryEvent) {
        dateFilter.minStartDate = events.minFilterDate.toFoundationDate()
        dateFilter.maxEndDate = events.maxFilterDate.toFoundationDate()
        dateFilter.startDate = events.filterStartDate.toFoundationDate()
        dateFilter.endDate = events.filterEndDate.toFoundationDate()
    }

    private func applyDiaryFilter(diaryFilter: DiaryFilter) {
        diaryFilterView.isHidden = getMapMeasureControl()?.measureStarted ?? false
        diaryFilterView.update(with: diaryFilter)

        // it is safe to display all marker types since filtering is done on the controller
        // side --> having filter here would mean double filtering
        markerManager.showOnlyMarkersOfType(markerTypes: GroupHuntingMarkerType.allCases)
    }

    private func centerMapToGroupAreaIfNeeded(huntingGroupArea: HuntingGroupArea?) {
        if (mapCenteredToGroupArea) {
            return
        }

        guard let huntingGroupArea = huntingGroupArea else { return }

        mapCenteredToGroupArea = true

        let bounds = GMSCoordinateBounds(
            coordinate: huntingGroupArea.bounds.minCoordinate.toCLLocationCoordinate2D(),
            coordinate: huntingGroupArea.bounds.maxCoordinate.toCLLocationCoordinate2D()
        )
        let cameraUpdate = GMSCameraUpdate.fit(bounds, withPadding: 50)

        mapView.animate(with: cameraUpdate)
    }

    private func displayGroupArea(huntingGroupArea: HuntingGroupArea?) {
        if (groupAreaLayerConfigured) {
            return
        }

        if let areaLayerId = groupAreaLayerId,
           let areaExternalId = huntingGroupArea?.externalId {

            mapView.configureMapLayer(layerId: areaLayerId, externalId: areaExternalId)
            groupAreaLayerConfigured = true
        }
    }

    // MARK: Diary filter dialog

    private func displayDiaryFilterUpdateDialog() {
        let viewModel = controllerHolder.controller.getLoadedViewModelOrNull()
        if let diaryFilter = viewModel?.events?.diaryFilter {
            displayDiaryFilterUpdateDialog(diaryFilter: diaryFilter)
        } else {
            print("No diary filter (viewmodel not loaded?)")
        }
    }

    private func displayDiaryFilterUpdateDialog(diaryFilter: DiaryFilter) {
        let dialogController = GroupHuntingUpdateDiaryFilterViewController()
        dialogController.initiallySelectedEventType = diaryFilter.eventType.toEventType()
        dialogController.initiallySelectedAcceptStatus = diaryFilter.acceptStatus.toAcceptStatus()

        dialogController.delegate = self

        present(dialogController, animated: true, completion:nil)
    }

    func onDiaryFilterChanged(eventType: DiaryFilterEventType, acceptStatus: DiaryFilterAcceptStatus) {
        let newDiaryFilter = DiaryFilter(
            eventType: eventType.toCommonEventType(),
            acceptStatus: acceptStatus.toCommonAcceptStatus()
        )

        controllerHolder.controller.eventDispatcher.dispatchDiaryFilterChanged(newDiaryFilter: newDiaryFilter)
    }


    // MARK: Harvest + Observation Click handling

    internal func onHarvestClicked(harvestId: ItemId, acceptStatus: RiistaCommon.AcceptStatus) {
        guard let harvestId = harvestId.remoteId else {
            print("harvestId didn't specify remoteId, cannot display harvest")
            return
        }

        // harvest can be clicked directly on the map but also from bottomsheet
        // -> ensure bottom sheet is dismissed before navigating forward
        bottomSheetHelper.dismiss() { [weak self] in
            guard let self = self else { return }

            let harvestTarget = GroupHuntingTargetKt.createTargetForHarvest(self.huntingGroupTarget, harvestId: harvestId)
            let viewHarvestController = ViewGroupHuntingHarvestViewController(
                harvestTarget: harvestTarget,
                acceptStatus: acceptStatus,
                listener: self
            )
            self.navigationController?.pushViewController(viewHarvestController, animated: true)
        }
    }

    internal func onObservationClicked(observationId: ItemId, acceptStatus: RiistaCommon.AcceptStatus) {
        guard let observationId = observationId.remoteId else {
            print("observationId didn't specify remoteId, cannot display observation")
            return
        }

        // observation can be clicked directly on the map but also from bottomsheet
        // -> ensure bottom sheet is dismissed before navigating forward
        bottomSheetHelper.dismiss() { [weak self] in
            guard let self = self else { return }

            let observationTarget = GroupHuntingTargetKt.createTargetForObservation(self.huntingGroupTarget, observationId: observationId)
            let viewObservationController = ViewGroupHuntingObservationViewController(
                observationTarget: observationTarget,
                acceptStatus: acceptStatus,
                listener: self
            )
            self.navigationController?.pushViewController(viewObservationController, animated: true)
        }
    }

    private func expandCluster(harvestIds: [Int64], observationIds: [Int64]) {
        let viewController = ListGroupDiaryEntriesViewController(
            huntingGroupTarget: self.huntingGroupTarget,
            harvestIds: harvestIds.map { KotlinLong(value: $0) },
            observationIds: observationIds.map { KotlinLong(value: $0) },
            listener: self
        )

        bottomSheetHelper.display(contentViewController: viewController)
    }


    // MARK: ViewGroupHarvestListener

    func onHarvestUpdated() {
        controllerHolder.shouldRefreshViewModel = true
    }


    // MARK: ViewGroupObservationListener

    func onObservationUpdated() {
        controllerHolder.shouldRefreshViewModel = true
    }


    // MARK: MapMeasureDistanceControlObserver

    func onMapMeasureStarted() {
        diaryFilterView.isHidden = true
    }

    func onMapMeasureEnded() {
        diaryFilterView.alpha = 0
        diaryFilterView.isHidden = false
        diaryFilterView.fadeIn(duration: AppConstants.Animations.durationShort)
    }
}
