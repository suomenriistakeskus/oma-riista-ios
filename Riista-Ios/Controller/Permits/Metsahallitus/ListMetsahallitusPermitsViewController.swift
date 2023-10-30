import Foundation
import UIKit
import Async
import SnapKit
import RiistaCommon


class ListMetsahallitusPermitsViewController:
    BaseControllerWithViewModel<ListMetsahallitusPermitsViewModel, ListMetsahallitusPermitsController>,
    ProvidesNavigationController, MetsahallitusPermitActionListener {

    private lazy var _controller: ListMetsahallitusPermitsController = {
        ListMetsahallitusPermitsController(
            usernameProvider: RiistaSDK.shared.currentUserContext,
            permitProvider: RiistaSDK.shared.metsahallitusPermits
        )
    }()

    override var controller: ListMetsahallitusPermitsController {
        get {
            _controller
        }
    }

    private lazy var tableViewController: MetsahallitusPermitsTableViewController = {
        let controller = MetsahallitusPermitsTableViewController()
        controller.actionListener = self
        return controller
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
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
        title = "MetsahallitusPermitsTitle".localized()
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

    override func onViewModelLoaded(viewModel: ListMetsahallitusPermitsViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        if (viewModel.permits.isEmpty) {
            showNoContentText(text: "MetsahallitusPermitsNoPermits".localized())
        } else {
            displayPermits(permits: viewModel.permits)
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

    private func displayPermits(permits: [CommonMetsahallitusPermit]) {
        hideNoContentText()
        tableViewController.setPermits(permits: permits)
    }

    private func showNoContentText(text: String?) {
        noContentArea.isHidden = false
        noContentLabel.text = text ?? ""
        tableViewController.setPermits(permits: [])
        tableView.isScrollEnabled = false
    }

    private func hideNoContentText() {
        noContentArea.isHidden = true
        tableView.isScrollEnabled = true
    }


    // MARK: MetsahallitusPermitActionListener

    func onViewMetsahallitusPermit(permit: CommonMetsahallitusPermit) {
        let viewController = ViewMetsahallitusPermitViewController(permitIdentifier: permit.permitIdentifier)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
