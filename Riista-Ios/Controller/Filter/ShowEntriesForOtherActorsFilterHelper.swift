import Foundation
import RiistaCommon

fileprivate let ICON_ONLY_MY_ENTRIES = UIImage(named: "user")
fileprivate let ICON_ENTRIES_FOR_OTHERS = UIImage(named: "user_group")

class ShowEntriesForOtherActorsFilterHelper: EntityFilterChangeListener {
    private lazy var logger = AppLogger(for: self, printTimeStamps: false)

    lazy var showEntriesForOtherActorsNavBarButton: HideableUIBarButtonItem = {
        let button = HideableUIBarButtonItem(
            image: ICON_ONLY_MY_ENTRIES,
            style: .plain,
            target: self,
            action: #selector(onShowEntriesForOtherActorsClicked)
        )
        return button
    }()

    var changeListener: EntityFilterChangeRequestListener? = nil

    private var showEntriesForOtherActors: Bool = false {
        didSet {
            if (showEntriesForOtherActors) {
                showEntriesForOtherActorsNavBarButton.image = ICON_ENTRIES_FOR_OTHERS
            } else {
                showEntriesForOtherActorsNavBarButton.image = ICON_ONLY_MY_ENTRIES
            }
        }
    }

    private var lastEntityFilter: EntityFilter? = nil

    @objc private func onShowEntriesForOtherActorsClicked() {
        logger.v { "show entries for other actors clicked, changing value to \(!showEntriesForOtherActors)" }

        let filter = lastEntityFilter ?? SharedEntityFilterState.shared.filter
        changeListener?.onFilterChangeRequested(
            filter: filter.changeShowEntriesForOtherActors(showEntriesForOtherActors: !showEntriesForOtherActors)
        )
    }

    private func canShowEntriesForOtherActors() -> Bool {
        HarvestSettingsControllerKt.showActorSelection(RiistaSDK.shared.preferences)
    }


    // MARK: EntityFilterChangeListener

    func onEntityFilterChanged(change: EntityFilterChange) {
        // keep track of the last filter as we're updating that one
        lastEntityFilter = change.filter

        if (!canShowEntriesForOtherActors()) {
            logger.v { "Hiding other actors navbar button, logging for others not enabled" }
            showEntriesForOtherActorsNavBarButton.shouldBeHidden = true
            return
        }

        guard let showEntriesForOtherActors = change.filter.showEntriesForOtherActors else {
            logger.v { "Hiding other actors navbar button, filter doesn't support other actors" }
            showEntriesForOtherActorsNavBarButton.shouldBeHidden = true
            return
        }

        self.showEntriesForOtherActors = showEntriesForOtherActors
        showEntriesForOtherActorsNavBarButton.shouldBeHidden = false
    }
}
