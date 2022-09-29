import Foundation
import SnapKit
import RiistaCommon

fileprivate class SimpleSelectableStringCell: UITableViewCell {
    static let REUSE_IDENTIFIER = "SimpleSelectableStringCell"

    let valueLabel: UILabel = {
        UILabel().configure(for: .inputValue, numberOfLines: 0)
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

    func bind(selectableString: SelectSingleStringViewController.SelectableString) {
        valueLabel.text = selectableString.value
    }
}

protocol SelectSingleStringViewControllerDelegate {
    func onStringSelected(string: SelectSingleStringViewController.SelectableString)
}

/**
 * A view controller for selecting single string without requiring user confirmation. Useful replacement e.g.
 * for drop down lists when list can have lots of entries.
 */
class SelectSingleStringViewController: UITableViewController {
    class SelectableString {
        let id: Int64
        let value: String

        init(id: Int64, value: String) {
            self.id = id
            self.value = value
        }
    }

    private var values: [SelectableString] = []
    var delegate: SelectSingleStringViewControllerDelegate?

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

        tableView.register(SimpleSelectableStringCell.self, forCellReuseIdentifier: SimpleSelectableStringCell.REUSE_IDENTIFIER)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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
        let cell = tableView.dequeueReusableCell(withIdentifier: SimpleSelectableStringCell.REUSE_IDENTIFIER) as! SimpleSelectableStringCell

        cell.bind(selectableString: value)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectableString = values[indexPath.row]
        delegate?.onStringSelected(string: selectableString)
        navigationController?.popViewController(animated: true)
    }
}


extension SelectSingleStringViewController {
    func setValues(values: [RiistaCommon.StringWithId]) {
        self.values = values.map { stringWithId in
            SelectableString(id: stringWithId.id, value: stringWithId.string)
        }
    }
}
