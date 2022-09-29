import Foundation
import RiistaCommon

class ListClubMembershipsTableViewController: NSObject, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView? {
        didSet {
            if let tableView = tableView {
                tableView.delegate = self
                tableView.dataSource = self
                registerCells(tableView: tableView)
            }
        }
    }

    private var huntingClubViewModels: [HuntingClubViewModel] = []
    weak var invitationActionListener: HuntingClubInvitationActionListener?

    func setHuntingClubs(huntingClubViewModels: [HuntingClubViewModel]) {
        self.huntingClubViewModels = huntingClubViewModels

        if let tableView = tableView {
            tableView.reloadData()
        } else {
            print("Did you forget to set tableView?")
        }
    }

    private func registerCells(tableView: UITableView) {
        tableView.register(HuntingClubMembershipCell.self, forCellReuseIdentifier: HuntingClubMembershipCell.reuseIdentifier)
        tableView.register(HuntingClubPendingInvitationCell.self, forCellReuseIdentifier: HuntingClubPendingInvitationCell.reuseIdentifier)
        tableView.register(HuntingClubMembershipsHeaderCell.self, forCellReuseIdentifier: HuntingClubMembershipsHeaderCell.reuseIdentifier)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        huntingClubViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = huntingClubViewModels[indexPath.row]

        if let header = viewModel as? HuntingClubViewModel.Header {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: HuntingClubMembershipsHeaderCell.reuseIdentifier,
                for: indexPath
            ) as! HuntingClubMembershipsHeaderCell
            cell.bind(header: header)

            return cell
        } else if let invitation = viewModel as? HuntingClubViewModel.Invitation {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: HuntingClubPendingInvitationCell.reuseIdentifier,
                for: indexPath
            ) as! HuntingClubPendingInvitationCell

            cell.actionListener = invitationActionListener
            cell.bind(invitation: invitation)

            return cell
        } else if let membership = viewModel as? HuntingClubViewModel.HuntingClub {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: HuntingClubMembershipCell.reuseIdentifier,
                for: indexPath
            ) as! HuntingClubMembershipCell
            cell.bind(membership: membership)

            return cell
        }

        fatalError("Unsupported cell type!")
    }

}
