import Foundation
import RiistaCommon
import TypedNotification

/*
 Documentation about filtering implementation

 Classes related to implementation
 - EntityFilter
    - base class for entity filters. Entity filter knows how to filter certain entity types
    - subclassed for harvests, observations, srvas and points of interest
 - FilterableEntityDataSource
    - base class for entity data sources. Entity data source is able to provide entities of one type.
    - subclassed for harvests, observations, srvas and points of interest
 - UnifiedEntityDataSource
    - combines harvest, observation, srva, point-of-interest data sources and provides access to the currently
      selected data source
    - subclassed for each use case: map, game log, gallery.
        - subclass needs to determine which data source types are supported
 - SharedEntityFilterState
    - shared filtering state
 - LogFilterView
    - UI for displaying current filter + delegates user actions via delegate

 Typical structure for a viewcontroller
    - use case specific DataSource that inherits UnifiedEntityDataSource
        - added as a listener to SharedEntityFilterState
        - added as a data source for logFilterView
    - viewcontroller
        - added as a listener to data source in order to update other UI than log filter view
    - log filter view
        - added as a listener for data source (display values used for determining displayed data)
        - configured to update SharedEntityFilterState (see SharedEntityFilterStateUpdater)

 Typical data flow (assuming typical structure)
    - LogFilterView: user makes a change,
    - SharedEntityFilterStateUpdater updates SharedEntityFilterState
    - SharedEntityFilterState.filter is updated, listeners are notified
    - DataSource (that inherits UnifiedEntityDataSource):
        - determines the filter to use
            - it is possible that shared filter state is not supported --> use one of the previous filters
        - using determined filter:
            - selects which FilterableEntityDataSource should be active
            - lets active FilterableEntityDataSource update itself (possibly async process)
    - DataSource filtering is changed, filter listeners are notified
        - LogFilterView is updated accordingly
        - ViewController is notified, other UI is updated
    - FilterableEntityDataSource entities are updated, notifies DataSource (that inherits UnifiedEntityDataSource)
    - DataSource updates UI + notifies possible listeners
*/

class SharedEntityFilterStateUpdater: EntityFilterChangeRequestListener {
    func onFilterChangeRequested(filter: EntityFilter) {
        SharedEntityFilterState.shared.updateFilter(filter: filter)
    }

    func onShowEntriesForOtherActorsChangeRequested(showEntriesForOtherActors: Bool) {
        let filter = SharedEntityFilterState.shared.filter
        SharedEntityFilterState.shared.updateFilter(
            filter: filter.changeShowEntriesForOtherActors(showEntriesForOtherActors: showEntriesForOtherActors)
        )
    }
}

// to be used from objective-c side
@objc class SharedEntityFilterStateHelper: NSObject {
    @objc class func registerToListenNotifications() {
        SharedEntityFilterState.shared.registerToListenNotifications()
    }
}

/**
 * Keeps track of shared EntityFilter thus allowing synchronization of LogFilterViews that are displayed in different view controllers.
 */
class SharedEntityFilterState {
    // initial / default state for filter
    static let DEFAULT_FILTER: EntityFilter = HarvestFilter(
        seasonStartYear: Int(Date().toLocalDate().getHuntingYear()),
        speciesCategory: nil,
        species: [],
        showEntriesForOtherActors: false
    )

    private(set) static var shared: SharedEntityFilterState = {
        SharedEntityFilterState(initialFilter: DEFAULT_FILTER)
    }()

    // the current filter
    private(set) var filter: EntityFilter {
        didSet {
            // updating latestFilterChange will notify listeners
            latestFilterChange = latestFilterChange.update(newFilter: filter)
        }
    }

    /**
     * The latest filter changes.
     */
    private var latestFilterChange = EntityFilterChange(newFilter: DEFAULT_FILTER) {
        didSet {
            filterChangeNotifier.notifyEntityFilterChanged(change: latestFilterChange)
        }
    }

    private let filterChangeNotifier = EntityFilterChangeNotifier()

    private lazy var notificationObservationBag = NotificationObservationBag()

    /**
     * Adds a EntityFilterChangeListener and optionally notifies it about the last shared state.
     *
     * Will keep a weak reference to listener.
     */
    func addEntityFilterChangeListener(_ listener: EntityFilterChangeListener, notify: Bool = true) {
        filterChangeNotifier.addEntityFilterChangeListener(listener)

        if (notify) {
            listener.onEntityFilterChanged(change: latestFilterChange)
        }
    }

    func removeEntityFilterChangeListener(_ listener: EntityFilterChangeListener) {
        filterChangeNotifier.removeEntityFilterChangeListener(listener)
    }

    func registerToListenNotifications() {
        NotificationCenter.default.addObserver(
            forType: EntityModified.self,
            object: nil,
            queue: .main
        ) { [weak self] entityModified in
            guard let self = self else {
                return
            }

            let newFilter = self.filter
                .changeEntityType(entityType: entityModified.object.entityType.toFilterableEntityType())
                .changeYear(year: entityModified.object.yearForFilter)
                .ensureSpeciesDisplayed(species: entityModified.object.entitySpecies)
                .changeShowEntriesForOtherActors(showEntriesForOtherActors: entityModified.object.entityReportedForOthers)

            self.updateFilter(filter: newFilter)
        }.stored(in: notificationObservationBag)
    }

    private init(initialFilter: EntityFilter) {
        filter = initialFilter
    }

    deinit {
        notificationObservationBag.empty()
    }


    // Modifying filter

    fileprivate func updateFilter(filter: EntityFilter) {
        // updating filter will cause notifications to listeners
        self.filter = filter
    }
}


fileprivate extension EntityModified.Data {
    var yearForFilter: Int {
        switch (entityType) {
        case .harvest:          fallthrough
        case .observation:      return Int(entityPointOfTime.date.getHuntingYear())
        case .srva:             return Int(entityPointOfTime.year)
        default:
            fatalError("Unexpected entity type \(entityType)")
        }
    }
}
