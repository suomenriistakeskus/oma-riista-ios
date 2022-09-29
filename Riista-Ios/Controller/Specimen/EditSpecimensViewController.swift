import Foundation
import UIKit
import SnapKit
import RiistaCommon

typealias OnSpecimensEditDone<FieldId : DataFieldId> = (_ fieldId: FieldId, _ specimenData: SpecimenFieldDataContainer) -> Void

class EditSpecimensViewController<FieldId : DataFieldId>:
    BaseControllerWithViewModel<EditSpecimensViewModel, EditSpecimensController>,
    ProvidesNavigationController {

    private let speciesNameResolver = SpeciesInformationResolver()
    private let tableViewController = DataFieldTableViewController<SpecimenFieldId>()
    private var specimenData: SpecimenFieldDataContainer
    private var fieldId: FieldId
    var onSpecimensEditDone: OnSpecimensEditDone<FieldId>? = nil

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

    private lazy var _controller: EditSpecimensController = {
        RiistaCommon.EditSpecimensController(
            speciesResolver: speciesNameResolver,
            stringProvider: LocalizedStringProvider()
        )
    }()

    override var controller: EditSpecimensController {
        get {
            _controller
        }
    }

    init(fieldId: FieldId, specimenData: SpecimenFieldDataContainer) {
        self.specimenData = specimenData
        self.fieldId = fieldId
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
            navigationControllerProvider: self,
            stringWithIdEventDispatcher: controller.eventDispatchers.stringWithIdDispatcher,
            genderEventDispatcher: controller.eventDispatchers.genderEventDispatcher,
            ageEventDispatcher: controller.eventDispatchers.ageEventDispatcher
        )
        tableViewController.addCellFactory(
            SpecimenHeaderFieldCell<SpecimenFieldId>.Factory<SpecimenFieldId>(clickHandler: { [weak self] fieldId in
                self?.onRemoveSpecimenClicked(fieldId: fieldId)
            })
        )

        title = "SpecimenDetailsTitle".localized()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.rightBarButtonItems = createRightBarButtonItems()
    }

    private func createRightBarButtonItems() -> [UIBarButtonItem] {
        [
            UIBarButtonItem(
                image: UIImage(named: "plus"),
                style: .plain,
                target: self,
                action: #selector(onAddSpecimenClicked)
           )
        ]
    }

    override func onWillLoadViewModel(willRefresh: Bool) {
        controller.loadSpecimenData(specimenData: specimenData) { _, _ in
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let viewModel = controller.getLoadedViewModelOrNull() {
            let specimenData = viewModel.specimenData
            onSpecimensEditDone?(fieldId, specimenData)
        }
    }


    override func onViewModelLoaded(viewModel: EditSpecimensViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)
        tableViewController.setDataFields(dataFields: viewModel.fields)
    }

    @objc func onAddSpecimenClicked() {
        controller.addSpecimen()
    }

    func onRemoveSpecimenClicked(fieldId: SpecimenFieldId) {
        controller.removeSpecimen(fieldId: fieldId)
    }
}
