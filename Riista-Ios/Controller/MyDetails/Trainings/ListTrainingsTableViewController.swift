import Foundation
import RiistaCommon

class ListTrainingsTableViewController: NSObject, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView? {
        didSet {
            if let tableView = tableView {
                tableView.delegate = self
                tableView.dataSource = self
                registerCells(tableView: tableView)
            }
        }
    }

    private var trainingViewModels: [TrainingViewModel] = []

    func setTrainings(trainingViewModels: [TrainingViewModel]) {
        self.trainingViewModels = trainingViewModels

        if let tableView = tableView {
            tableView.reloadData()
        } else {
            print("Did you forget to set tableView?")
        }
    }

    private func registerCells(tableView: UITableView) {
        tableView.register(JhtTrainingCell.self, forCellReuseIdentifier: JhtTrainingCell.reuseIdentifier)
        tableView.register(OccupationTrainingCell.self, forCellReuseIdentifier: OccupationTrainingCell.reuseIdentifier)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        trainingViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = trainingViewModels[indexPath.row]

        if let training = viewModel as? TrainingViewModel.JhtTraining {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: JhtTrainingCell.reuseIdentifier,
                for: indexPath
            ) as! JhtTrainingCell
            cell.bind(training: training)
            return cell

        } else if let training = viewModel as? TrainingViewModel.OccupationTraining {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: OccupationTrainingCell.reuseIdentifier,
                for: indexPath
            ) as! OccupationTrainingCell
            cell.bind(training: training)
            return cell
        }

        fatalError("Unsupported cell type!")
    }

}

