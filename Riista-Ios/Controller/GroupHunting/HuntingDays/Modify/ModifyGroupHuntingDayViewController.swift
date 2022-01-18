import Foundation
import UIKit
import SnapKit
import RiistaCommon


protocol ModifyGroupHuntingDayViewControllerDelegate: AnyObject {
    func onHuntingDaySaved()
}

class ModifyGroupHuntingDayViewController<Controller : ModifyGroupHuntingDayController>:
    BaseControllerWithViewModel<ModifyGroupHuntingDayViewModel, Controller>,
    ProvidesNavigationController,
    KeyboardHandlerDelegate {

    private(set) weak var delegate: ModifyGroupHuntingDayViewControllerDelegate?

    private let tableViewController = DataFieldTableViewController<GroupHuntingDayField>()
    private var keyboardHandler: KeyboardHandler?

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

    private lazy var buttonArea: UIView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = 8
        view.backgroundColor = UIColor.applicationColor(ViewBackground)
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = AppConstants.UI.DefaultEdgeInsets

        view.addArrangedSubview(cancelButton)
        view.addArrangedSubview(saveButton)
        view.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight + view.layoutMargins.top + view.layoutMargins.bottom)
        }

        let separator = SeparatorView(orientation: .horizontal)
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        return view
    }()

    private lazy var cancelButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyOutlinedTheme(withScheme: AppTheme.shared.outlineButtonScheme())
        btn.setTitle("Cancel".localized(), for: .normal)
        btn.onClicked = { [weak self] in
            self?.onCancelClicked()
        }
        return btn
    }()

    private(set) lazy var saveButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        btn.setTitle("Save".localized(), for: .normal)
        btn.onClicked = { [weak self] in
            self?.onSaveClicked()
        }
        return btn
    }()

    init(delegate: ModifyGroupHuntingDayViewControllerDelegate) {
        self.delegate = delegate
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
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }

        container.addArrangedSubview(tableView)
        container.addArrangedSubview(buttonArea)

        keyboardHandler = KeyboardHandler(
            view: view,
            contentMovement: .adjustContentInset(scrollView: tableView)
        )
        keyboardHandler?.delegate = self
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.addDefaultCellFactories(
            navigationControllerProvider: self,
            stringWithIdEventDispatcher: controller.eventDispatchers.stringWithIdDispatcher,
            intEventDispatcher: controller.eventDispatchers.intEventDispatcher,
            localDateTimeEventDispacter: controller.eventDispatchers.dateTimeEventDispatcher,
            hoursAndMinutesEventDispatcher: controller.eventDispatchers.durationEventDispatcher
        )

        title = "GroupHuntingHuntingDay".localized()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navController = navigationController as? RiistaNavigationController {
            navController.setRightBarItems(nil)
        }

        keyboardHandler?.listenKeyboardEvents()
    }

    override func viewWillDisappear(_ animated: Bool) {
        keyboardHandler?.hideKeyboard()
        keyboardHandler?.stopListenKeyboardEvents()

        super.viewWillDisappear(animated)
    }

    override func onViewModelLoaded(viewModel: ModifyGroupHuntingDayViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)
        tableViewController.setDataFields(dataFields: viewModel.fields)

        saveButton.isEnabled = viewModel.huntingDayCanBeSaved
    }

    func onSaveClicked() {
        fatalError("You should subclass this class and override onSaveClicked()")
    }

    func onCancelClicked() {
        navigationController?.popViewController(animated: true)
    }


    // MARK: KeyboardHandlerDelegate

    func getBottommostVisibleViewWhileKeyboardVisible() -> UIView? {
        tableView
    }
}
