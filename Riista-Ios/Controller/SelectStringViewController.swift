import Foundation
import SnapKit
import RiistaCommon

fileprivate class SelectableStringCell: UITableViewCell {
    static let REUSE_IDENTIFIER = "SelectableStringCell"

    let valueLabel: UILabel = {
        let label = UILabel()
        AppTheme.shared.setupValueFont(label: label)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.numberOfLines = 0
        return label
    }()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(AppConstants.UI.DefaultButtonHeight).priority(999)
        }
        separatorInset = UIEdgeInsets(top: 0, left: AppConstants.UI.DefaultHorizontalInset,
                                      bottom: 0, right: AppConstants.UI.DefaultHorizontalInset)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func bind(selectableString: SelectStringViewController.SelectableString) {
        valueLabel.text = selectableString.value
    }
}

protocol SelectStringViewControllerDelegate {
    func onStringSelected(string: SelectStringViewController.SelectableString)
}

class SelectStringViewController: UITableViewController {
    class SelectableString {
        let id: Int64
        let value: String

        init(id: Int64, value: String) {
            self.id = id
            self.value = value
        }
    }

    private var values: [SelectableString] = []
    var delegate: SelectStringViewControllerDelegate?

    func setValues(values: [String]) {
        self.values = values.enumerated().map { (index, value) in
            SelectableString(id: Int64(index), value: value)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            // the layoutMargins we're setting may be less than system minimum layou margins..
            viewRespectsSystemMinimumLayoutMargins = false
        }
        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.separatorStyle = .singleLine
        tableView.estimatedRowHeight = AppConstants.UI.ButtonHeightSmall
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()

        tableView.register(SelectableStringCell.self, forCellReuseIdentifier: SelectableStringCell.REUSE_IDENTIFIER)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navController = navigationController as? RiistaNavigationController {
            navController.setRightBarItems(nil)
        }
        tableView.flashScrollIndicators()
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        values.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let value = values[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectableStringCell.REUSE_IDENTIFIER) as! SelectableStringCell

        cell.bind(selectableString: value)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectableString = values[indexPath.row]
        delegate?.onStringSelected(string: selectableString)
        navigationController?.popViewController(animated: true)
    }
}


extension SelectStringViewController {
    func setValues(values: [RiistaCommon.StringWithId]) {
        self.values = values.map { stringWithId in
            SelectableString(id: stringWithId.id, value: stringWithId.string)
        }
    }
}
