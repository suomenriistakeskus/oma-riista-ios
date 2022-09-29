import Foundation
import RiistaCommon


protocol PointOfInterestFilterViewControllerDelegate: AnyObject {
    func onPointOfInterestFilterChanged(pointOfInterestFilterType: PointOfInterestFilterType)
}

class PointOfInterestFilterViewController: MaterialDialogViewController {

    weak var delegate: PointOfInterestFilterViewControllerDelegate?

    var initiallySelectedFilterType: PointOfInterestFilterType?
    let filterTypeRadioGroup = RadioButtonGroup<PointOfInterestFilterType>()

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

        filterTypeRadioGroup.animationContainerView = selectionsStackView

        for filterType in PointOfInterestFilterType.allCases {
            let filterTypeView = RadioButtonWithLabel(labelText: filterType.localized().uppercased())
            filterTypeView.isSelected = filterType == initiallySelectedFilterType
            selectionsStackView.addView(filterTypeView)
            filterTypeRadioGroup.addSelectable(filterTypeView, data: filterType)
        }
    }

    override func onOkClicked() {
        let selectedFilterType: PointOfInterestFilterType? = filterTypeRadioGroup.getSelectedData()

        if let delegate = delegate, let filterType = selectedFilterType {
            delegate.onPointOfInterestFilterChanged(pointOfInterestFilterType: filterType)
        }
        super.onOkClicked()
    }
}
