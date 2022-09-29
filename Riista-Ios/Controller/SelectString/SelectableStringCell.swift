import Foundation
import MaterialComponents
import RiistaCommon
import UIKit

protocol SelectableStringCellListener: AnyObject {
    func onSelectableStringClicked(stringWithId: StringWithId)
}

class SelectableStringCell: UITableViewCell {
    static let reuseIdentifier = "SelectableStringCell"

    /**
     * A listener for the click events.
     */
    weak var listener: SelectableStringCellListener? = nil

    private weak var boundSelectableString: SelectableStringWithId?

    private let viewBackground = OverlayView()

    private lazy var label: UILabel = {
        UILabel().configure(
            for: .navigationBar,
            numberOfLines: 0
        )
    }()

    private lazy var checkIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.applicationColor(Primary)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(selectableString: SelectableStringWithId) {
        label.text = selectableString.value.string
        if (selectableString.selected) {
            checkIconView.image = CHECK_ICON
        } else {
            checkIconView.image = nil
        }

        boundSelectableString = selectableString
    }

    private func commonInit() {
        // detect cell clicks using a view that is bottommost in the subview stack
        let clickableBackground = ClickableCellBackground().apply { background in
            background.onClicked = { [weak self] in
                guard let selectableString = self?.boundSelectableString else {
                    return
                }

                self?.listener?.onSelectableStringClicked(stringWithId: selectableString.value)
            }
        }
        contentView.addSubview(clickableBackground)
        contentView.addSubview(viewBackground)

        // the actual visible views / data
        let viewContainer = OverlayView()
        contentView.addSubview(viewContainer)

        viewBackground.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalTo(viewContainer)
        }
        clickableBackground.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalTo(viewContainer)
        }
        viewContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(1) // inset by separator height
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight - 1).priority(999)
        }

        viewContainer.addSubview(label)
        viewContainer.addSubview(checkIconView)
        label.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.trailing.equalTo(checkIconView.snp.leading).offset(-8)
        }
        checkIconView.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }


        let separator = SeparatorView(orientation: .horizontal)
        contentView.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.bottom.equalToSuperview()
        }
    }
}

fileprivate let CHECK_ICON = UIImage(named: "check_white")
