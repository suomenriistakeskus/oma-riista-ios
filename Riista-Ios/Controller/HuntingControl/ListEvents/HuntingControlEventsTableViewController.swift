import Foundation
import DifferenceKit
import RiistaCommon

fileprivate class HuntingControlEventHolder: Differentiable {
    private(set) var event: SelectHuntingControlEvent

    var differenceIdentifier: Int {
        get {
            event.id.hashValue
        }
    }

    init(event: SelectHuntingControlEvent) {
        self.event = event
    }

    func isContentEqual(to source: HuntingControlEventHolder) -> Bool {
        // SelectHuntingControlEvent are data classes in common lib -> use hash
        return event.hashValue == source.event.hashValue
    }
}

class HuntingControlEventsTableViewController: NSObject, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView? {
        didSet {
            if let tableView = tableView {
                tableView.delegate = self
                tableView.dataSource = self
                registerCells(tableView: tableView)
            }
        }
    }

    weak var viewEventListener: ViewHuntingControlEventListener?

    private var eventHolders: [HuntingControlEventHolder] = []
    private var noEventsText: String = "HuntingControlNoEvents".localized()

    func setHuntingControlEvents(events: [SelectHuntingControlEvent]) {
        let newHolders = events.map { HuntingControlEventHolder(event: $0) }

        if let tableView = tableView {
            // Don't try to perform partial update when switching from <no hunting control events> to
            // <there are events> (or vice versa). Partial update will crash the app as "No events" cell
            // is hardcoded and doesn't really exist in eventHolders. And since it doesn't exist in
            // eventHolders the partial update doesn't know how to handle it --> crash
            // (crash only occurred during tests when this function was called during viewDidAppear,
            //  calling it during viewWillAppear doesn't seem to crash the app probably because
            //  reload(stagedChangeSet) will perform reloadData if tableView doesn't have window)
            if (self.eventHolders.isEmpty != newHolders.isEmpty) {
                eventHolders = newHolders
                tableView.reloadData()
            } else {
                let stagedChangeSet = StagedChangeset(source: self.eventHolders, target: newHolders)
                tableView.reload(using: stagedChangeSet, with: .fade) { newHolders in
                    self.eventHolders = newHolders
                }
            }
        } else {
            self.eventHolders = newHolders
            print("Did you forget to set tableView?")
        }
    }

    func showNoHuntingControlEventsText(_ text: String) {
        noEventsText = text

        // noEventsText is displayed in a cell
        tableView?.reloadData()
    }

    private func registerCells(tableView: UITableView) {
        tableView.register(HuntingControlEventCell.self, forCellReuseIdentifier: HuntingControlEventCell.reuseIdentifier)
        tableView.register(NoHuntingControlEventsCell.self, forCellReuseIdentifier: NoHuntingControlEventsCell.reuseIdentifier)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(eventHolders.count, 1) // at least 1 in order to show "no events text"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (eventHolders.isEmpty) {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: NoHuntingControlEventsCell.reuseIdentifier,
                for: indexPath
            ) as! NoHuntingControlEventsCell

            cell.text = noEventsText

            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: HuntingControlEventCell.reuseIdentifier,
            for: indexPath
        ) as! HuntingControlEventCell

        cell.listener = viewEventListener
        cell.bind(event: eventHolders[indexPath.row].event)

        return cell
    }
}
