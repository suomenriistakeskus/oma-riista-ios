import Foundation
import UIKit
import Async
import SnapKit
import RiistaCommon
import MaterialComponents

protocol ListClubMembershipsViewControllerListener: AnyObject {
    func onClubInvitationAcceptedOrRejected()
}

class ListClubMembershipsViewController:
    BaseControllerWithViewModel<ListHuntingClubsViewModel, HuntingClubController>,
    HuntingClubInvitationActionListener {

    weak var listener: ListClubMembershipsViewControllerListener?

    private lazy var _controller: RiistaCommon.HuntingClubController = {
        RiistaCommon.HuntingClubController(
            huntingClubsContext: RiistaSDK.shared.currentUserContext.huntingClubsContext,
            usernameProvider: RiistaSDK.shared.currentUserContext,
            huntingClubOccupationsProvider: RiistaSDK.shared.huntingClubOccupations,
            languageProvider: CurrentLanguageProvider(),
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: HuntingClubController {
        get {
            _controller
        }
    }

    private lazy var tableViewController: ListClubMembershipsTableViewController = {
        let controller = ListClubMembershipsTableViewController()

        controller.invitationActionListener = self
        return controller
    }()

    private lazy var tableView: TableView = {
        let tableView = TableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension

        tableViewController.tableView = tableView

        return tableView
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            self,
            action: #selector(onRefreshRequested),
            for: .valueChanged
        )

        return refreshControl
    }()

    private lazy var refreshNavBarButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(named: "refresh_white"),
            style: .plain,
            target: self,
            action: #selector(onRefreshClicked)
        )
    }()

    private lazy var noContentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(GreyDark)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var noContentArea: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .vertical
        stackview.alignment = .fill
        stackview.spacing = 12

        stackview.addArrangedSubview(noContentLabel)
        stackview.isHidden = true
        return stackview
    }()

    override func loadView() {
        super.loadView()

        indicateLoadingStateUsingRefreshIndicator = false

        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        let tableViewContainer = UIView()
        tableViewContainer.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableViewContainer.addSubview(noContentArea)
        noContentArea.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        container.addArrangedSubview(tableViewContainer)

        tableView.refreshControl = refreshControl
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "MyDetailsClubMembershipsTitle".localized()
        navigationItem.rightBarButtonItems = [refreshNavBarButton]
    }

    override func viewWillDisappear(_ animated: Bool) {
        hideRefreshIndicator()
        super.viewWillDisappear(animated)
    }

    @objc func onRefreshClicked() {
        // starting refreshing programmatically will cause refresh control to emit corresponding event
        // -> onRefreshRequested will be called
        refreshControl.beginRefreshingProgrammatically()
    }

    @objc func onRefreshRequested() {
        refreshNavBarButton.isEnabled = false

        // typically refresh is very fast i.e. it completes within few hundred milliseconds. If that is the case
        // the load indicator only flashes which makes the UI look broken. Delay the start of the load operation
        // so that it would appear that loading actually takes bit more time. It's also more convincing that way i.e.
        // "app is actually doing something right now"
        Async.main(after: 0.5) { [weak self] in
            self?.controllerHolder.loadViewModel(refresh: true)
        }
    }

    override func onViewModelLoaded(viewModel: ListHuntingClubsViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        if (!viewModel.items.isEmpty) {
            hideNoContentText()
            tableViewController.setHuntingClubs(huntingClubViewModels: viewModel.items)
        } else {
            showNoContentText(text: "HuntingClubNoMemberships".localized())
        }
    }

    override func onLoadViewModelCompleted() {
        super.onLoadViewModelCompleted()
        hideRefreshIndicator()
    }

    private func hideRefreshIndicator() {
        refreshControl.endRefreshing()
        refreshNavBarButton.isEnabled = true
    }

    private func showNoContentText(text: String?) {
        noContentArea.isHidden = false
        noContentLabel.text = text ?? ""
        tableViewController.setHuntingClubs(huntingClubViewModels: [])
        tableView.isScrollEnabled = false
    }

    private func hideNoContentText() {
        noContentArea.isHidden = true
        tableView.isScrollEnabled = true
    }

    func onAcceptInvitationRequested(invitation: HuntingClubViewModel.Invitation) {
        tableView.showLoading()

        controller.acceptInvitation(
            invitationId: invitation.invitationId,
            completionHandler: handleOnMainThread { [weak self] response, _ in
                guard let self = self else { return }

                self.tableView.hideLoading()
                if (response is HuntingClubMemberInvitationOperationResponse.Success) {
                    // data refreshed internally
                    self.listener?.onClubInvitationAcceptedOrRejected()
                    self.controllerHolder.loadViewModel(refresh: false)
                } else {
                    self.showNetworErrorDialog()
                }
            }
        )
    }

    func onRejectInvitationRequested(invitation: HuntingClubViewModel.Invitation) {
        let dialog = MDCAlertController(title: "AreYouSure".localized(),
                                        message: "HuntingClubMembershipRejectInvitationQuestion".localized())
        dialog.addAction(MDCAlertAction(title: "No".localized(), handler: { _ in
            // nop
        }))
        dialog.addAction(MDCAlertAction(title: "Yes".localized(), handler: { _ in
            self.rejectInvitation(invitation: invitation)
        }))

        present(dialog, animated: true, completion: nil)
    }

    private func rejectInvitation(invitation: HuntingClubViewModel.Invitation) {
        tableView.showLoading()

        controller.rejectInvitation(
            invitationId: invitation.invitationId,
            completionHandler: handleOnMainThread { [weak self] response, _ in
                guard let self = self else { return }

                self.tableView.hideLoading()
                if (response is HuntingClubMemberInvitationOperationResponse.Success) {
                    // data refreshed internally
                    self.listener?.onClubInvitationAcceptedOrRejected()
                    self.controllerHolder.loadViewModel(refresh: false)
                } else {
                    self.showNetworErrorDialog()
                }
            }
        )
    }

    private func showNetworErrorDialog() {
        let dialog = AlertDialogBuilder.createError(message: "NetworkOperationFailed".localized())
        self.navigationController?.present(dialog, animated: true, completion: nil)
    }
}
