import Foundation
import UIKit
import MaterialComponents
import SnapKit
import RiistaCommon


class ListSelectableStringsView: UIView {

    // MARK: Common callbacks + settings

    var onSelectButtonClicked: OnClicked?
    var onCancelButtonClicked: OnClicked?

    var canSelect: Bool = false {
        didSet {
            selectButton.isEnabled = canSelect
        }
    }

    private(set) lazy var contentArea: UIStackView = {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill

        container.addView(filterArea)
        container.addView(tableView)
        container.addView(bottomButtonsArea)

        return container
    }()

    private(set) lazy var filterArea: UIStackView = {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill
        container.spacing = 4

        container.isLayoutMarginsRelativeArrangement = true
        container.layoutMargins = AppConstants.UI.DefaultEdgeInsets

        container.addView(filterTextFieldAndLabel)
        container.addSeparatorToBottom(respectLayoutMarginsGuide: false)

        return container
    }()

    var filterText: String = "" {
        didSet {
            filterTextFieldAndLabel.textField.text = filterText
        }
    }

    var onFilterTextChanged: OnTextChanged? = nil {
        didSet {
            filterTextFieldAndLabel.onTextChanged = onFilterTextChanged
        }
    }

    private(set) lazy var filterTextFieldAndLabel: TextFieldAndLabel = {
        let textFieldAndLabel = TextFieldAndLabel()
        textFieldAndLabel.isEnabled = true
        return textFieldAndLabel
    }()

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.tableFooterView = nil
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension

        return tableView
    }()

    // area for the buttons at the bottom of the screen
    private(set) lazy var bottomButtonsArea: UIView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = 8
        view.backgroundColor = UIColor.applicationColor(ViewBackground)
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = AppConstants.UI.DefaultEdgeInsets

        view.addArrangedSubview(cancelButton)
        view.addArrangedSubview(selectButton)
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
            self?.onCancelButtonClicked?()
        }
        return btn
    }()

    private lazy var selectButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        btn.setTitle("Select".localized(), for: .normal)
        btn.onClicked = { [weak self] in
            self?.onSelectButtonClicked?()
        }
        btn.isEnabled = canSelect
        return btn
    }()


    func showFilter(label: String?, placeholder: String?) {
        filterArea.isHidden = false
        if let label = label {
            filterTextFieldAndLabel.captionLabel.text = label
            filterTextFieldAndLabel.captionLabel.isHidden = false
        } else {
            filterTextFieldAndLabel.captionLabel.isHidden = true
        }

        filterTextFieldAndLabel.textField.placeholder = placeholder
    }

    func hideFilter() {
        filterArea.isHidden = true
    }


    // MARK: Init

    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        addSubview(contentArea)
        contentArea.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
