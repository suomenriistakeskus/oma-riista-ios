import Foundation
import DropDown
import MaterialComponents
import RiistaCommon


class SunriseAndSunsetTimesViewController:
    BaseControllerWithViewModel<SunriseAndSunsetTimesViewModel, SunriseAndSunsetTimesController>,
    ProvidesNavigationController, LocationListener
{
    private lazy var _controller: SunriseAndSunsetTimesController = {
        SunriseAndSunsetTimesController(
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: SunriseAndSunsetTimesController {
        get {
            _controller
        }
    }

    /**
     * A location manager for updating the location if needed.
     */
    private let locationManager = LocationManager()


    private let tableViewController = DataFieldTableViewController<SunriseAndSunsetField>()

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

    init() {
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
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.addDefaultCellFactories(
            navigationControllerProvider: self,
            locationEventDispatcher: self.controller.eventDispatchers.locationEventDispatcher,
            localDateEventDispatcher: self.controller.eventDispatchers.localDateEventDispatcher
        )

        title = "SunriseAndSunsetTitle".localized()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (controller.locationCanBeUpdatedAutomatically) {
            locationManager.addListener(self)
            locationManager.start()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        locationManager.removeListener(self)
    }

    override func onViewModelLoaded(viewModel: SunriseAndSunsetTimesViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        tableViewController.setDataFields(dataFields: viewModel.fields)
    }

    func onLocationChanged(newLocation: CLLocation?) {
        guard let etrsLocation = newLocation?.coordinate.toETRSCoordinate(source: .manual) else {
            return
        }

        let locationChanged = controller.trySelectCurrentUserLocation(location: etrsLocation)
        if (!locationChanged) {
            locationManager.removeListener(self, stopIfLastListener: true)
        }
    }
}
