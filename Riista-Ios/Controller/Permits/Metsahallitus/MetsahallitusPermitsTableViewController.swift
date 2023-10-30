import Foundation
import DifferenceKit
import RiistaCommon

fileprivate class MetsahallitusPermitHolder: Differentiable {
    private(set) var permit: CommonMetsahallitusPermit

    var differenceIdentifier: Int {
        get {
            permit.permitIdentifier.hashValue
        }
    }

    init(permit: CommonMetsahallitusPermit) {
        self.permit = permit
    }

    func isContentEqual(to source: MetsahallitusPermitHolder) -> Bool {
        // permits are data classes in common lib -> use hash
        return permit.hashValue == source.permit.hashValue
    }
}

class MetsahallitusPermitsTableViewController: NSObject, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView? {
        didSet {
            if let tableView = tableView {
                tableView.delegate = self
                tableView.dataSource = self
                registerCells(tableView: tableView)
            }
        }
    }

    weak var actionListener: MetsahallitusPermitActionListener?

    private var permitHolders: [MetsahallitusPermitHolder] = []

    func setPermits(permits: [CommonMetsahallitusPermit]) {
        let newHolders = permits.map { MetsahallitusPermitHolder(permit: $0) }

        if let tableView = tableView {
            let stagedChangeSet = StagedChangeset(source: self.permitHolders, target: newHolders)
            tableView.reload(using: stagedChangeSet, with: .fade) { newHolders in
                self.permitHolders = newHolders
            }
        } else {
            self.permitHolders = newHolders
            print("Did you forget to set tableView?")
        }
    }

    private func registerCells(tableView: UITableView) {
        tableView.register(MetsahallitusPermitCell.self, forCellReuseIdentifier: MetsahallitusPermitCell.reuseIdentifier)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        permitHolders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MetsahallitusPermitCell.reuseIdentifier,
            for: indexPath
        ) as! MetsahallitusPermitCell

        cell.listener = actionListener
        cell.bind(permit: permitHolders[indexPath.row].permit)

        return cell
    }
}
