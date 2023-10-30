import Foundation
import UIKit
import SnapKit
import RiistaCommon


class ListPointsOfInterestViewController:
    BaseControllerWithViewModel<PoiListViewModel, PoiListController>,
    ProvidesNavigationController, PointOfInterestActionListener {

    private let areaExternalId: String?
    private let pointOfInterestFilter: PoiFilter

    private lazy var _controller: RiistaCommon.PoiListController = {
        RiistaCommon.PoiListController(
            poiContext: RiistaSDK.shared.poiContext,
            externalId: areaExternalId,
            filter: pointOfInterestFilter
        )
    }()

    override var controller: PoiListController {
        get {
            _controller
        }
    }

    private lazy var tableViewController: PointOfInterestTableViewController = {
        let controller = PointOfInterestTableViewController()
        controller.actionListener = self
        return controller
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60
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

    init(areaExternalId: String?, pointOfInterestFilter: PoiFilter) {
        self.areaExternalId = areaExternalId
        self.pointOfInterestFilter = pointOfInterestFilter

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func loadView() {
        super.loadView()

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
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "PointOfInterestListTitle".localized()
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

    override func onViewModelLoaded(viewModel: PoiListViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        let visibleItems = viewModel.visibleItems
        if (!visibleItems.isEmpty) {
            hideNoContentText()
            tableViewController.setPointOfInterestItems(pointOfInterestItems: viewModel.visibleItems)
        } else {
            showNoContentText(text: "PointOfInterestNoPois".localized())
        }
    }

    private func showNoContentText(text: String?) {
        noContentArea.isHidden = false
        noContentLabel.text = text ?? ""
        tableViewController.setPointOfInterestItems(pointOfInterestItems: [])
        tableView.isScrollEnabled = false
    }

    private func hideNoContentText() {
        noContentArea.isHidden = true
        tableView.isScrollEnabled = true
    }

    override func onViewModelLoadFailed() {
        super.onViewModelLoadFailed()
        showNoContentText(text: "PointOfInterestNoPois".localized())
    }


    // MARK: - PointOfInterestActionListener

    func onPointOfInterestGroupClicked(groupItem: PoiListItem.PoiGroupItem) {
        controller.eventDispatcher.dispatchPoiGroupSelected(groupId: groupItem.id)
    }

    func onPointOfInterestClicked(item: PoiListItem.PoiItem) {
        guard let areaExternalId = self.areaExternalId else {
            return
        }

        let viewController = ViewPointOfInterestViewController(
            areaExternalId: areaExternalId,
            pointOfInterestGroupId: item.groupId,
            pointOfInterestId: item.id
        )

        navigationController?.pushViewController(viewController, animated: true)
    }
}
