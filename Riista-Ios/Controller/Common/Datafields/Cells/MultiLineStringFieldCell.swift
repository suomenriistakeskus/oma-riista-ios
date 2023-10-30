import Foundation
import SnapKit
import RiistaCommon


fileprivate let CELL_TYPE = DataFieldCellType.stringMultiLine
fileprivate let TEXT_VIEW_FONT = UIFont.appFont(for: .inputValue)
fileprivate let MIN_TEXT_VIEW_HEIGHT = ceil(TEXT_VIEW_FONT.lineHeight)

class MultiLineStringFieldCell<FieldId : DataFieldId>:
    TypedDataFieldCell<FieldId, StringField<FieldId>>,
    UITextViewDelegate {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var eventDispatcher: StringEventDispatcher?

    var isEnabled: Bool = false {
        didSet {
            if (isEnabled != oldValue) {
                onEnabledChanged()
            }
        }
    }

    private(set) var editingText: Bool = false {
        didSet {
            if (editingText != oldValue) {
                updateLineColor()
            }
        }
    }

    private(set) lazy var topLevelContainer: UIView = {
        let container = UIView()
        return container
    }()

    private(set) lazy var captionLabel: LabelView = {
        let labelView = LabelView()
        return labelView
    }()

    private lazy var textViewAndLine: UIView = {
        let container = UIView()
        container.addSubview(textView)
        container.addSubview(lineUnderTextField)
        lineUnderTextField.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        textView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(lineUnderTextField.snp.top).offset(-4)
        }
        return container
    }()

    private(set) lazy var textView: UITextView = {
        let textView = UITextView()

        textView.textColor = UIColor.applicationColor(TextPrimary)
        textView.font = TEXT_VIEW_FONT
        textView.autocorrectionType = .no
        textView.textAlignment = .left
        textView.isScrollEnabled = false

        textView.inputAccessoryView = KeyboardToolBar().hideKeyboardOnDone(editView: textView)

        // remove left/right paddings
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero

        textView.delegate = self
        return textView
    }()

    private var textViewHeightConstraint: Constraint? = nil

    private(set) lazy var lineUnderTextField: SeparatorView = {
        // bg color of the separator updated when isEnabled status is taken into account
        SeparatorView(orientation: .horizontal)
    }()

    override var containerView: UIView {
        return topLevelContainer
    }

    override func createSubviews(for container: UIView) {
        container.addSubview(captionLabel)
        container.addSubview(textViewAndLine)

        captionLabel.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }

        textViewAndLine.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(captionLabel.snp.bottom).offset(6)
        }

        container.snp.makeConstraints { make in
            make.bottom.greaterThanOrEqualTo(textViewAndLine).priority(500)
        }

        textView.snp.makeConstraints { make in
            textViewHeightConstraint = make.height
                .equalTo(0)
                .offset(MIN_TEXT_VIEW_HEIGHT)
                .priority(999)
                .constraint
        }

        onEnabledChanged()
    }

    override func fieldWasBound(field: StringField<FieldId>) {
        if let label = field.settings.label {
            captionLabel.text = label
            captionLabel.required = field.settings.requirementStatus.isVisiblyRequired()
            captionLabel.isHidden = false
        } else {
            captionLabel.isHidden = true
        }

        if (!field.settings.readOnly && eventDispatcher != nil) {
            isEnabled = true
        } else {
            isEnabled = false
            if (!field.settings.readOnly) {
                print("No event dispatcher, displaying field \(field.id_) in disabled mode!")
            }
        }
        textView.text = field.value

        let textHeight = ceil(
            field.value.getPreferredSize(
                font: textView.font,
                maxWidth: tableView?.layoutMarginsGuide.layoutFrame.width ?? textView.frame.width
            ).height
        )
        let currentHeight = textView.frame.height
        let targetHeight = max(MIN_TEXT_VIEW_HEIGHT, textHeight)

        if (abs(currentHeight - targetHeight) > 1) {
            textViewHeightConstraint?.update(offset: targetHeight)

            // animate small changes as those are most likely because of user edits. Don't animate
            // large changes as those are likely because of re-using cell for different purposes
            let animateChanges = abs(currentHeight - targetHeight) < 2*MIN_TEXT_VIEW_HEIGHT // i.e. less than 2 line difference
            setCellNeedsLayout(animateChanges: animateChanges)
        }
    }

    func onTextChanged(text: String) {
        dispatchValueChanged(
            eventDispatcher: eventDispatcher,
            value: text
        ) { eventDispatcher, fieldId, text in
            eventDispatcher.dispatchStringChanged(fieldId: fieldId, value: text)
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text else {
            return
        }

        onTextChanged(text: text)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        editingText = true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        editingText = false
    }

    private func onEnabledChanged() {
        updateTextFieldEnabledIndication()
        updateLineColor()
    }

    private func updateTextFieldEnabledIndication() {
        textView.isEditable = isEnabled
        if (isEnabled) {
            textView.textColor = UIColor.applicationColor(TextPrimary)
        } else {
            textView.textColor = UIColor.applicationColor(GreyMedium)
        }
    }

    private func updateLineColor() {
        let lineColor: UIColor
        if (editingText) {
            lineColor = UIColor.applicationColor(Primary)
        } else {
            if (isEnabled) {
                lineColor = UIColor.applicationColor(TextPrimary)
            } else {
                lineColor = UIColor.applicationColor(GreyMedium)
            }
        }

        if (lineUnderTextField.backgroundColor != lineColor) {
            UIView.animate(withDuration: AppConstants.Animations.durationShort) { [weak self] in
                self?.lineUnderTextField.backgroundColor = lineColor
            }
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        let eventDispatcher: StringEventDispatcher?

        init(eventDispatcher: StringEventDispatcher?) {
            self.eventDispatcher = eventDispatcher
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(MultiLineStringFieldCell<FieldId>.self,
                               forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView,
                                 indexPath: IndexPath,
                                 dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! MultiLineStringFieldCell<FieldId>

            cell.eventDispatcher = eventDispatcher

            return cell
        }
    }
}
