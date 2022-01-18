import Foundation
import DifferenceKit
import RiistaCommon

fileprivate class HuntingDayHolder: Differentiable {
    private(set) var huntingDayViewModel: SelectableHuntingDayViewModel

    var differenceIdentifier: Int {
        get {
            huntingDayViewModel.huntingDayId.hashValue
        }
    }

    init(huntingDayViewModel: SelectableHuntingDayViewModel) {
        self.huntingDayViewModel = huntingDayViewModel
    }

    func isContentEqual(to source: HuntingDayHolder) -> Bool {
        // HuntingDayViewModels are data classes in common lib -> use hash
        return huntingDayViewModel.hashValue == source.huntingDayViewModel.hashValue
    }
}

class SelectableHuntingDaysTableViewController: NSObject, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView? {
        didSet {
            if let tableView = tableView {
                tableView.delegate = self
                tableView.dataSource = self
                registerCells(tableView: tableView)
            }
        }
    }

    private var huntingDayHolders: [HuntingDayHolder] = []
    private weak var huntingDayListener: SelectableHuntingDayCellListener?

    init(huntingDayListener: SelectableHuntingDayCellListener) {
        self.huntingDayListener = huntingDayListener
    }

    func setHuntingDays(huntingDays: [SelectableHuntingDayViewModel]) {
        let newHolders = huntingDays.map { HuntingDayHolder(huntingDayViewModel: $0) }

        if let tableView = tableView {
            let stagedChangeSet = StagedChangeset(source: self.huntingDayHolders, target: newHolders)
            tableView.reload(using: stagedChangeSet, with: .fade) { newHolders in
                self.huntingDayHolders = newHolders
            }
        } else {
            self.huntingDayHolders = newHolders
            print("Did you forget to set tableView?")
        }
    }

    private func registerCells(tableView: UITableView) {
        tableView.register(SelectableHuntingDayCell.self, forCellReuseIdentifier: SelectableHuntingDayCell.reuseIdentifier)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        huntingDayHolders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SelectableHuntingDayCell.reuseIdentifier,
            for: indexPath
        ) as! SelectableHuntingDayCell

        cell.listener = huntingDayListener
        cell.bind(huntingDayViewModel: huntingDayHolders[indexPath.row].huntingDayViewModel)

        return cell
    }
}
