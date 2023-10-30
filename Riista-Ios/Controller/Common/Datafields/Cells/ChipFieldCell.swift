import Foundation
import MaterialComponents
import SnapKit
import RiistaCommon
import UIKit
import Async


fileprivate let CELL_TYPE = DataFieldCellType.chip
fileprivate let CHIP_CELL_REUSEIDENTIFIER = "ChipCellReuseIdentifier"
fileprivate let DELETE_CHIP_IMAGE = UIImage(named: "cancel")?.withRenderingMode(.alwaysTemplate)


class ChipFieldCell<FieldId : DataFieldId>:
    TypedDataFieldCell<FieldId, ChipField<FieldId>>,
    UICollectionViewDataSource {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private weak var eventDispatcher: StringWithIdClickEventDispatcher? = nil

    private(set) lazy var topLevelContainer: UIStackView = {
        // use a vertical stackview for containing label + chips
        // -> allows hiding caption if necessary
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 6
        container.alignment = .fill
        return container
    }()

    private lazy var label: LabelView = {
        return LabelView()
    }()

    private lazy var chipCollectionView: UICollectionView = {
        // use only MDCChipCollectionViewFlowLayout from the MaterialComponents/Chips
        // - the chips provided by MaterialComponents have animations (e.g. ripple + shadow) which we
        //   don't want to due to chosen Model-View-Intent architecture (controller determines selected
        //   chips and we don't want to have stateful chips / collection view)
        let layout = MDCChipCollectionViewFlowLayout()

        // use automatic size so that chips are able to resize themselves correctly (i.e. they won't
        // overlap each other)
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(ChipCollectionViewCell.self, forCellWithReuseIdentifier: CHIP_CELL_REUSEIDENTIFIER)
        collectionView.dataSource = self

        // background color required for iOS10 as otherwise background was black
        collectionView.backgroundColor = UIColor.applicationColor(ViewBackground)

        collectionView.snp.makeConstraints { make in
            // setup the default height using offset. This allows changing the height by
            // adjusting the offset when subviews are layouted which allows displaying
            // all chips (i.e. if last fall e.g. to second row)
            chipCollectionViewHeightConstraint = make.height.equalTo(0).offset(50).priority(999).constraint
        }

        return collectionView
    }()

    // for adjusting the tableview cell to have correct height when collection view
    // content is updated
    private var cachedCollectionViewContentHeight: CGFloat = 0.0
    private var chipCollectionViewHeightConstraint: Constraint?

    override var containerView: UIView {
        return topLevelContainer
    }

    override func createSubviews(for container: UIView) {
        guard let container = container as? UIStackView else {
            fatalError("Expected UIStackView as container!")
        }

        container.addArrangedSubview(label)
        container.addArrangedSubview(chipCollectionView)
    }

    override func fieldWasBound(field: ChipField<FieldId>) {
        if let labelText = field.settings.label {
            label.isHidden = false
            if (field.settings.readOnly) {
                // adjust to appear like read-only, single line cell
                label.label.font = UIFont.appFont(fontSize: .small, fontWeight: .semibold)
                label.text = labelText.uppercased()
            } else {
                label.label.configure(for: .label, fontWeight: .semibold)
                label.text = labelText
            }
            label.required = field.settings.requirementStatus.isVisiblyRequired()
        } else {
            label.isHidden = true
        }

        chipCollectionView.reloadData()

        // tableview seems to be quite picky about how and when cells can be updated
        // if their contents change. Relayouting just here wasn't enough e.g. for iOS 12.4
        // simulator and thus perform the re-layout again after a while. Yes, it's a hackish
        // approach but should alleviate some UI glitches
        relayoutAfterBinding()
        Async.main(after: 0.3) { [weak self] in
            self?.relayoutAfterBinding()
        }
    }

    private func relayoutAfterBinding() {
        // fix iOS10 crash caused by
        // "UICollectionView received layout attributes for a cell with an index path that does not exist"
        //
        // The crash occurs when chips are altered after initial layout (e.g. chips selected in different view)
        // after which the cell will get a new field that will be bound
        // TODO: check if this prevents the crash also when decreasing the number of chips
        chipCollectionView.collectionViewLayout.invalidateLayout()

        // re-layout the collectionview so that it has a chance to update content size thus
        // allowing this cell to update its height constraint
        chipCollectionView.setNeedsLayout()
        chipCollectionView.layoutIfNeeded()

        // ask tableview to re-layout this cell. Otherwise cell will have incorrect height occasionally
        // - animations should only occur if cell has already been visible beforehand
        //   i.e. the content was updated
        // - without animations the updates are NOT applied
        setCellNeedsLayout(animateChanges: bindingState == .updated)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let contentHeight = chipCollectionView.collectionViewLayout.collectionViewContentSize.height
        if (abs(cachedCollectionViewContentHeight - contentHeight) > 0.1) {
            chipCollectionViewHeightConstraint?.update(offset: contentHeight)
            cachedCollectionViewContentHeight = contentHeight

            // apply animations when content has been updated. Without animations the height is not updated
            // (don't ask why, seems to be tableview quirk)
            setCellNeedsLayout(animateChanges: bindingState == .updated)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        boundField?.chips.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CHIP_CELL_REUSEIDENTIFIER,
            for: indexPath
        ) as! ChipCollectionViewCell

        guard let field = boundField else {
            return cell
        }

        if let chip = field.chips.getOrNil(index: indexPath.row) {
            let selected = field.selectedIds?.contains(where: { selectedId in
                selectedId.int64Value == chip.id
            }) == true

            cell.bind(chip: chip, mode: field.settings.mode.toChipMode(), selected: selected)

            cell.onClicked = { [weak self] in
                self?.eventDispatcher?.dispatchStringWithIdClicked(fieldId: field.id_, value: chip)
            }
        }
        return cell
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {

        private weak var eventDispatcher: StringWithIdClickEventDispatcher? = nil

        init(eventDispatcher: StringWithIdClickEventDispatcher?) {
            super.init(cellType: CELL_TYPE)
            self.eventDispatcher = eventDispatcher
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(ChipFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! ChipFieldCell<FieldId>

            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}



fileprivate class ChipCollectionViewCell: UICollectionViewCell {
    static private let BTN_CONTENT_EDGE_INSETS = UIEdgeInsets(
        top: 0, left: AppConstants.UI.ButtonHeightSmall / 4,
        bottom: 0, right: AppConstants.UI.ButtonHeightSmall / 4
    )

    var chipSelected: Bool = false {
        didSet {
            updateColors()
        }
    }

    var onClicked: OnClicked?

    private(set) lazy var button: ButtonWithRoundedCorners = {
        let btn = ButtonWithRoundedCorners()
        btn.titleLabel?.font = UIFont.appFont(for: .label)
        btn.roundedCorners = .allCorners()
        btn.cornerRadius = AppConstants.UI.ButtonHeightSmall / 2
        btn.contentEdgeInsets = ChipCollectionViewCell.BTN_CONTENT_EDGE_INSETS
        btn.addTarget(self, action: #selector(handleButtonClick), for: .touchUpInside)

        btn.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func bind(chip: StringWithId, mode: ChipMode, selected: Bool) {
        button.setTitle(chip.string, for: .normal)
        self.chipSelected = selected

        switch (mode) {
        case .view:         configureChipForViewMode()
        case .delete:       configureChipForDeleteMode()
        case .toggle:       configureChipForToggleMode()
        }
    }

    private func configureChipForViewMode() {
        button.isEnabled = false
        button.setSpacingBetweenImageAndTitle(spacing: 0, contentEdgeInsets: ChipCollectionViewCell.BTN_CONTENT_EDGE_INSETS)
        button.setImage(nil, for: .normal)
    }

    private func configureChipForDeleteMode() {
        button.isEnabled = true
        button.setImage(DELETE_CHIP_IMAGE, for: .normal)
        button.setSpacingBetweenImageAndTitle(spacing: 8, contentEdgeInsets: ChipCollectionViewCell.BTN_CONTENT_EDGE_INSETS)
        button.imageView?.tintColor = UIColor.applicationColor(Destructive)
    }

    private func configureChipForToggleMode() {
        button.isEnabled = true
        button.setImage(nil, for: .normal)
        button.setSpacingBetweenImageAndTitle(spacing: 0, contentEdgeInsets: ChipCollectionViewCell.BTN_CONTENT_EDGE_INSETS)
        button.imageView?.tintColor = UIColor.applicationColor(Destructive)
    }

    @objc private func handleButtonClick() {
        onClicked?()
    }

    private func updateColors() {
        if (chipSelected) {
            button.backgroundColor = UIColor.applicationColor(Primary)
            button.setTitleColor(UIColor.applicationColor(TextOnPrimary), for: .normal)
        } else {
            button.backgroundColor = UIColor.applicationColor(GreyLight)
            button.setTitleColor(UIColor.applicationColor(TextPrimary), for: .normal)
        }
    }

    private func setup() {
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}


fileprivate enum ChipMode {
    case view, delete, toggle
}

fileprivate extension ChipFieldMode {
    func toChipMode() -> ChipMode {
        switch self {
        case ChipFieldMode.view:        return .view
        case ChipFieldMode.delete_:     return .delete
        case ChipFieldMode.toggle:      return .toggle
        default:
            print("Unexpected chip field mode \(self), defaulting to .view")
            return .view
        }
    }
}

