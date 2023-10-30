import Foundation
import RiistaCommon

class HarvestSettingsViewController:
    BaseControllerWithViewModel<HarvestSettingsViewModel, HarvestSettingsController>
{
    private lazy var _controller: HarvestSettingsController = {
        HarvestSettingsController(
            stringProvider: LocalizedStringProvider(),
            preferences: RiistaSDK.shared.preferences
        )
    }()

    override var controller: HarvestSettingsController {
        get {
            _controller
        }
    }

    private let tableViewController = DataFieldTableViewController<HarvestSettingsField>()

    private(set) lazy var tableView: TableView = {
        let tableView = TableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension

        tableViewController.setTableView(tableView)
        return tableView
    }()

    override func loadView() {
        super.loadView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.addDefaultCellFactories(
            booleanEventDispatcher: controller.eventDispatchers.booleanEventDispatcher
        )

        title = "HarvestSettings".localized()
    }

    override func onViewModelLoaded(viewModel: ViewModelType) {
        super.onViewModelLoaded(viewModel: viewModel)
        tableViewController.setDataFields(dataFields: viewModel.fields)
    }
}
