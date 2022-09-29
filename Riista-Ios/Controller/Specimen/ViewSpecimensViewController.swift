import Foundation
import RiistaCommon

class ViewSpecimensViewController:
    BaseControllerWithViewModel<ViewSpecimensViewModel, ViewSpecimensController>,
    ProvidesNavigationController {

    private let speciesNameResolver = SpeciesInformationResolver()
    private let tableViewController = DataFieldTableViewController<SpecimenFieldId>()
    private var specimenData: SpecimenFieldDataContainer

    private(set) lazy var tableView: TableView = {
        let tableView = TableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 70
        tableView.rowHeight = UITableView.automaticDimension

        tableViewController.setTableView(tableView)
        return tableView
    }()

    private lazy var _controller: ViewSpecimensController = {
        ViewSpecimensController(
            speciesResolver: speciesNameResolver,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: ViewSpecimensController {
        get {
            _controller
        }
    }

    init(specimenData: SpecimenFieldDataContainer) {
        self.specimenData = specimenData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func loadView() {
        super.loadView()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.addDefaultCellFactories(
            navigationControllerProvider: self
        )

        title = "SpecimenDetailsTitle".localized()
    }

    override func onWillLoadViewModel(willRefresh: Bool) {
        controller.loadSpecimenData(specimenData: specimenData) { _, _ in
        }
    }

    override func onViewModelLoaded(viewModel: ViewSpecimensViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)
        tableViewController.setDataFields(dataFields: viewModel.fields)
    }
}
