import Foundation
import SnapKit
import RiistaCommon

/**
 * A base class for data field cells that:
 * - does not contain generic FieldType parameter (otherwise we're hitting the wall of covariance with factories)
 * - provides an API for binding DataField
 */
class DataFieldCell<FieldId : DataFieldId>: TableViewCell {

    /**
     * Subclasses are required to specify the type of the DataFieldCell. Will be used for determining
     * the reuseIdentifier.
     */
    var cellType: DataFieldCellType {
        fatalError("Subclasses must implement cellType")
    }

    override var reuseIdentifier: String? {
        get {
            cellType.reuseIdentifier
        }
    }

    /**
     * The default containerView to be used.
     */
    private lazy var defaultContainerView: UIView = {
        UIView()
    }()

    /**
     * Subclasses should override this if different containerView should be added to contentView.
     */
    var containerView: UIView {
        defaultContainerView
    }

    /**
     * A constraint for specifying the top padding.
     */
    var topPaddingConstraint: Constraint?

    /**
     * A constraint for specifying the bottom padding.
     */
    var bottomPaddingConstraint: Constraint?

    /**
     * The cell internal top padding.
     *
     * For example button like cells may have internal padding in order to make clickable area larger.
     */
    var internalTopPadding: CGFloat { return 0 }

    /**
     * The cell internal bottom padding.
     *
     * For example button like cells may have internal padding in order to make clickable area larger.
     */
    var internalBottomPadding: CGFloat { return 0 }

    override init(style: CellStyle, reuseIdentifier: String?) {
        // reuseIdentifier overridden, no need to pass to super
        super.init(style: .default, reuseIdentifier: nil)
        initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeViews()
    }

    func initializeViews() {
        addContainerViewToContentViewAndSpecifyConstraints(container: containerView)
        createSubviews(for: containerView)
    }

    /**
     * Subclass this if you need different paddings for the cell. By default the cell will follow the contentView.layoutMarginsGuide.
     */
    func addContainerViewToContentViewAndSpecifyConstraints(container: UIView) {
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            topPaddingConstraint = make.top.equalToSuperview().constraint
            bottomPaddingConstraint = make.bottom.equalToSuperview().constraint
        }
    }

    func createSubviews(for container: UIView) {
        fatalError("DataFieldCell needs to be subclassed!")
    }


    // MARK: Rebind support

    /**
     * Is the currenty bound field same (i.e. same id) as the given field.
     *
     * The content equality should _NOT_ be checked.
     */
    func isBound(field: DataField<FieldId>) -> Bool {
        fatalError("Subclassing needed")
    }

    /**
     * Rebinds the given field if data has been changed.
     *
     * @return true if data was changed, false otherwise.
     */
    func rebindIfChanged(field: DataField<FieldId>) -> Bool {
        fatalError("Subclassing needed")
    }

    func bind(field: DataField<FieldId>) {
        updateTopAndBottomPaddings(field: field)
    }

    func updateTopAndBottomPaddings(field: DataField<FieldId>) {
        let paddingTop = field.settings.paddingTop
        let paddingBottom = field.settings.paddingBottom

        topPaddingConstraint?.update(offset: max(0, paddingTop.getPaddingInPoints() - internalTopPadding))
        bottomPaddingConstraint?.update(offset: min(0, -paddingBottom.getPaddingInPoints() + internalBottomPadding))
    }
}

fileprivate extension Padding {
    func getPaddingInPoints() -> CGFloat {
        switch self {
        case .none:         return 0
        case .small:        return 4
        case .smallMedium:  return 8
        case .medium:       return 12
        case .mediumLarge:  return 16
        case .large:        return 24
        default:
            print("Unexpected Padding value \(self). Returning fallback value")
            return 8
        }
    }
}

/**
 * The actual base class for cells.
 *
 * Provides the means of casting the DataField to the correct subtype.
 */
class TypedDataFieldCell<FieldId : DataFieldId, FieldType: DataField<FieldId>>: DataFieldCell<FieldId> {
    var boundField: FieldType? = nil

    enum BindingState {
        /**
         * No DataField has been bound
         */
        case notBound

        /**
         * A DataField has been bound once.
         */
        case initialized

        /**
         * A DataField was bound before and it has now been updated
         */
        case updated
    }

    private(set) var bindingState: BindingState = .notBound

    /**
     * Is the cell currently dispatching value changed?
     */
    private(set) var dispatchingValueChanged: Bool = false


    // MARK: Rebind support

    override func isBound(field: DataField<FieldId>) -> Bool {
        boundField?.isSame(other: field) == true
    }

    override func rebindIfChanged(field: DataField<FieldId>) -> Bool {
        if (!isBound(field: field)) {
            print("Cannot rebind \(field.id_), different field / not bound before")
            return false
        }

        if let boundField = boundField, let field = field as? FieldType {
            if (!boundField.isContentSame(other: field)) {
                doBind(field: field, rebind: true)
                return true
            } else {
                return false
            }
        } else {
            // consider removing this error at some point
            // -> it is better to display data incorrectly than crash all apps
            fatalError("Unexpected DataField \(field.id_) type for cell observed!")
        }
    }

    override func bind(field: DataField<FieldId>) {
        super.bind(field: field)

        if let field = field as? FieldType {
            doBind(field: field, rebind: false)
        } else {
            // consider removing this error at some point
            // -> it is better to display data incorrectly than crash all apps
            fatalError("Unexpected DataField type for cell observed!")
        }
    }

    private func doBind(field: FieldType, rebind: Bool) {
        if let currentField = boundField, currentField.isContentSame(other: field) {
            print("Field \(field.id_) contents remained same, won't \(rebind ? "rebind" : "bind")!")
            boundField = field // probably not needed but shouldn't hurt either
            return
        }

        fieldWillBeBound(field: field)
        boundField = field
        print("\(rebind ? "Rebinding" : "Binding") field \(field.id_) to cell \(Unmanaged.passUnretained(self).toOpaque())")
        fieldWasBound(field: field)
        updateBindingStateAfterFieldWasBound()
    }

    func fieldWillBeBound(field: FieldType) {
        // nop
    }

    func fieldWasBound(field: FieldType) {
        // nop
    }

    private func updateBindingStateAfterFieldWasBound() {
        switch bindingState {
        case .notBound:
            bindingState = .initialized
            break
        case .initialized:
            bindingState = .updated
            break
        default:
            break
        }
    }

    func dispatchValueChanged<EventDispatcher, ValueType>(
        eventDispatcher: EventDispatcher?,
        value: ValueType?,
        _ dispatchBlock: (EventDispatcher, FieldId, ValueType) -> Void
    ) {
        guard let fieldId = boundField?.id_ else {
            print("No bound field, cannot dispatch value change!")
            return
        }

        dispatchValueChanged(fieldId: fieldId, eventDispatcher: eventDispatcher, value: value, dispatchBlock)
    }

    func dispatchValueChanged<EventDispatcher, ValueType>(
        fieldId: FieldId,
        eventDispatcher: EventDispatcher?,
        value: ValueType?,
        _ dispatchBlock: (EventDispatcher, FieldId, ValueType) -> Void
    ) {
        if let dispatcher = eventDispatcher, let value = value {
            dispatchingValueChanged = true
            dispatchBlock(dispatcher, fieldId, value)
            dispatchingValueChanged = false
        } else {
            print("Cannot dispatch value change for \(fieldId), no event dispatcher or value is nil")
        }
    }

    func dispatchNullableValueChanged<EventDispatcher, ValueType>(
        eventDispatcher: EventDispatcher?,
        value: ValueType?,
        _ dispatchBlock: (EventDispatcher, FieldId, ValueType?) -> Void
    ) {
        guard let fieldId = boundField?.id_ else {
            print("No bound field, cannot dispatch value change!")
            return
        }

        if let dispatcher = eventDispatcher {
            dispatchingValueChanged = true
            dispatchBlock(dispatcher, fieldId, value)
            dispatchingValueChanged = false
        } else {
            print("Cannot dispatch value change for \(fieldId), no event dispatcher")
        }
    }
}

class DataFieldCellFactory<FieldId : DataFieldId> {
    let cellType: DataFieldCellType

    init(cellType: DataFieldCellType) {
        self.cellType = cellType
    }

    func registerCellType(to tableView: UITableView) {
        fatalError("Subclasses are required to implement this function")
    }

    func canCreateCell(for dataField: DataField<FieldId>) -> Bool {
        true
    }

    func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
        fatalError("Subclasses are required to implement this function")
    }
}
