import Foundation
import SnapKit
import RiistaCommon

protocol SelectStringViewControllerDelegate: AnyObject {
    func onStringsSelected(selecteStrings: [StringWithId])
}


/**
 * A view controller for selecting single or multiple strings. Requires user confirmation.
 */
class SelectStringViewController:
    BaseControllerWithViewModel<SelectStringWithIdViewModel, SelectStringWithIdController>,
    ProvidesNavigationController, SelectableStringCellListener {

    private let mode: StringListFieldMode
    private let allValues: [StringWithId]
    private let selectedValues: [KotlinLong]

    var filterEnabled: Bool = false
    var filterLabelText: String? = nil
    var filterTextHint: String? = nil

    var delegate: SelectStringViewControllerDelegate?

    private lazy var _controller: RiistaCommon.SelectStringWithIdController = {
        RiistaCommon.SelectStringWithIdController(
            mode: mode,
            possibleValues: allValues,
            initiallySelectedValues: selectedValues
        )
    }()

    override var controller: SelectStringWithIdController {
        get {
            _controller
        }
    }

    private lazy var tableViewController: SelectStringTableViewController = {
        let controller = SelectStringTableViewController()
        controller.tableView = selectableStringsView.tableView
        controller.clickListener = self
        return controller
    }()

    private lazy var selectableStringsView: ListSelectableStringsView = {
        let view = ListSelectableStringsView()
        view.onFilterTextChanged = { [weak self] text in
            self?.onFilterTextChanged(text: text)
        }
        view.onCancelButtonClicked = { [weak self] in
            self?.onCancelClicked()
        }
        view.onSelectButtonClicked = { [weak self] in
            self?.onSelectClicked()
        }
        return view
    }()


    init(
        mode: StringListFieldMode,
        allValues: [StringWithId],
        selectedValues: [KotlinLong]
    ) {
        self.mode = mode
        self.allValues = allValues
        self.selectedValues = selectedValues

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func loadView() {
        super.loadView()

        view.addSubview(selectableStringsView)
        selectableStringsView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }

        if (filterEnabled) {
            selectableStringsView.showFilter(label: filterLabelText, placeholder: filterTextHint)
        } else {
            selectableStringsView.hideFilter()
        }
    }

    private func onFilterTextChanged(text: String) {
        controller.eventDispatcher.dispatchFilterChanged(filter: text)
    }

    private func onSelectClicked() {
        guard let selectedValues = controller.getLoadedViewModelOrNull()?.selectedValues else {
            print("No selected values, cannot notify")
            return
        }

        delegate?.onStringsSelected(selecteStrings: selectedValues)
        navigationController?.popViewController(animated: true)
    }

    private func onCancelClicked() {
        navigationController?.popViewController(animated: true)
    }

    override func onViewModelLoaded(viewModel: SelectStringWithIdViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        if let selectedValues = viewModel.selectedValues {
            selectableStringsView.canSelectHuntingDay = !selectedValues.isEmpty
        } else {
            selectableStringsView.canSelectHuntingDay = false
        }

        selectableStringsView.filterText = viewModel.filter

        tableViewController.setSelectableStrings(viewModel.filteredValues)
    }

    func onSelectableStringClicked(stringWithId: StringWithId) {
        controller.eventDispatcher.dispatchSelectedValueChanged(value: stringWithId)
    }

}


