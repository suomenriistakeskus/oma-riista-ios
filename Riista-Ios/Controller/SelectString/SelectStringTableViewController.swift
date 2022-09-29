import Foundation
import DifferenceKit
import RiistaCommon

fileprivate class SelectableStringHolder: Differentiable {
    private(set) var selectableString: SelectableStringWithId

    var differenceIdentifier: Int {
        get {
            selectableString.value.id.hashValue
        }
    }

    init(selectableString: SelectableStringWithId) {
        self.selectableString = selectableString
    }

    func isContentEqual(to source: SelectableStringHolder) -> Bool {
        // SelectableStringWithId are data classes in common lib -> use hash
        return selectableString.hashValue == source.selectableString.hashValue
    }
}

class SelectStringTableViewController: NSObject, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView? {
        didSet {
            if let tableView = tableView {
                tableView.delegate = self
                tableView.dataSource = self
                registerCells(tableView: tableView)
            }
        }
    }

    weak var clickListener: SelectableStringCellListener? = nil

    private var selectableStringHolders: [SelectableStringHolder] = []

    func setSelectableStrings(_ selectableStrings: [SelectableStringWithId]) {
        let newHolders = selectableStrings.map { SelectableStringHolder(selectableString: $0) }

        if let tableView = tableView {
            let stagedChangeSet = StagedChangeset(source: self.selectableStringHolders, target: newHolders)
            tableView.reload(using: stagedChangeSet, with: .fade) { newHolders in
                self.selectableStringHolders = newHolders
            }
        } else {
            self.selectableStringHolders = newHolders
            print("Did you forget to set tableView?")
        }
    }

    private func registerCells(tableView: UITableView) {
        tableView.register(
            SelectableStringCell.self,
            forCellReuseIdentifier: SelectableStringCell.reuseIdentifier
        )
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectableStringHolders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SelectableStringCell.reuseIdentifier,
            for: indexPath
        ) as! SelectableStringCell

        cell.listener = clickListener
        cell.bind(selectableString: selectableStringHolders[indexPath.row].selectableString)

        return cell
    }
}
