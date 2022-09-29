import Foundation
import RiistaCommon


protocol GroupHuntingUpdateDiaryFilterViewControllerDelegate: AnyObject {
    func onDiaryFilterChanged(eventType: DiaryFilterEventType, acceptStatus: DiaryFilterAcceptStatus)
}

class GroupHuntingUpdateDiaryFilterViewController: MaterialDialogViewController {

    weak var delegate: GroupHuntingUpdateDiaryFilterViewControllerDelegate?

    var initiallySelectedEventType: DiaryFilterEventType?
    let eventTypeRadioGroup = RadioButtonGroup<DiaryFilterEventType>()

    var initiallySelectedAcceptStatus: DiaryFilterAcceptStatus?
    let acceptStatusRadioGroup = RadioButtonGroup<DiaryFilterAcceptStatus>()

    override func loadView() {
        super.loadView()

        titleLabel.text = "FilterDialogTitle".localized()

        let selectionsStackView = UIStackView()
        selectionsStackView.axis = .vertical
        selectionsStackView.alignment = .fill
        contentViewContainer.addSubview(selectionsStackView)
        selectionsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        eventTypeRadioGroup.animationContainerView = selectionsStackView
        acceptStatusRadioGroup.animationContainerView = selectionsStackView

        for eventType in DiaryFilterEventType.allCases {
            let eventTypeView = RadioButtonWithLabel(labelText: eventType.localized().uppercased())
            eventTypeView.isSelected = eventType == initiallySelectedEventType
            selectionsStackView.addView(eventTypeView)
            eventTypeRadioGroup.addSelectable(eventTypeView, data: eventType)
        }
        selectionsStackView.addSeparator()

        for acceptStatus in DiaryFilterAcceptStatus.allCases {
            let acceptStatusView = RadioButtonWithLabel(labelText: acceptStatus.localized().uppercased())
            acceptStatusView.isSelected = acceptStatus == initiallySelectedAcceptStatus
            selectionsStackView.addView(acceptStatusView)
            acceptStatusRadioGroup.addSelectable(acceptStatusView, data: acceptStatus)
        }
    }

    override func onOkClicked() {
        let selectedEventype: DiaryFilterEventType? = eventTypeRadioGroup.getSelectedData()
        let selectedAcceptStatus: DiaryFilterAcceptStatus? = acceptStatusRadioGroup.getSelectedData()

        if let delegate = delegate, let eventType = selectedEventype, let acceptStatus = selectedAcceptStatus {
            delegate.onDiaryFilterChanged(eventType: eventType, acceptStatus: acceptStatus)
        }
        super.onOkClicked()
    }
}
