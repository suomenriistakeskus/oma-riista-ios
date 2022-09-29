import Foundation
import RiistaCommon

class ListTrainingsViewController:
    BaseControllerWithViewModel<ListTrainingsViewModel, ListTrainingsController> {

    private lazy var _controller: RiistaCommon.ListTrainingsController = {
        RiistaCommon.ListTrainingsController(
            trainingContext: RiistaSDK.shared.currentUserContext.trainingContext,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: ListTrainingsController {
        get {
            _controller
        }
    }

    private lazy var tableViewController: ListTrainingsTableViewController = {
        let controller = ListTrainingsTableViewController()
        return controller
    }()

    private lazy var tableView: TableView = {
        let tableView = TableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 70
        tableView.rowHeight = UITableView.automaticDimension

        tableViewController.tableView = tableView

        return tableView
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

        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
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
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "MyDetailsTrainingsTitle".localized()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.rightBarButtonItems = createNavigationBarItems()
    }

    private func createNavigationBarItems() -> [UIBarButtonItem] {
        [
            UIBarButtonItem(
                image: UIImage(named: "refresh_white"),
                style: .plain,
                target: self,
                action: #selector(onRefreshClicked)
            )
        ]
    }

    @objc func onRefreshClicked() {
        controllerHolder.loadViewModel(refresh: true)
    }

    override func onViewModelLoaded(viewModel: ListTrainingsViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        if (!viewModel.trainings.isEmpty) {
            hideNoContentText()
            tableViewController.setTrainings(trainingViewModels: viewModel.trainings)
        } else {
            showNoContentText(text: "MyDetailsNoTrainings".localized())
        }
    }

    private func showNoContentText(text: String?) {
        noContentArea.isHidden = false
        noContentLabel.text = text ?? ""
        tableViewController.setTrainings(trainingViewModels: [])
        tableView.isScrollEnabled = false
    }

    private func hideNoContentText() {
        noContentArea.isHidden = true
        tableView.isScrollEnabled = true
    }

    override func onViewModelLoadFailed() {
        super.onViewModelLoadFailed()
    }

}
