import Foundation

typealias OnSelectedDataChanged<Data> = (_ data: Data?) -> Void

/**
 * A SelectionController that only allows one Selectable to be selected at any time (i.e. radio button group)
 *
 * Does not monitor Selectables i.e. it is possible to have multiple selections if set directly to Selectables.
 * Does not require Selectables to be RadioButton instances i.e. allows different kinds of UIs.
 */
class RadioButtonGroup<Data : Equatable>: SelectionControllerWithData<Data> {

    /**
     * The view that will be used as animation container
     */
    weak var animationContainerView: UIView?

    var onSelectionChanged: OnSelectedDataChanged<Data>?

    override func onSelectableClicked(indicator: SelectionIndicator) {
        let clickedSelectable = selectables.first { selectable in
            selectable.indicator === indicator
        }

        if (clickedSelectable?.indicator.isSelected == true) {
            print("already selected")
            return
        }

        if let animationContainerView = animationContainerView {
            UIView.transition(
                with: animationContainerView,
                duration: AppConstants.Animations.durationShort,
                options: .transitionCrossDissolve,
                animations: { [weak self] in
                    self?.select(selectable: clickedSelectable)
                },
                completion: { [weak self] _ in
                    self?.onSelectionChanged?(clickedSelectable?.data)
                })
        } else {
            print("No animation container view, cannot animate")
            select(selectable: clickedSelectable)
        }
    }

    func select(data: Data) {
        let shouldBeSelected = selectables.first { selectable in
            selectable.data == data
        }

        select(selectable: shouldBeSelected)
    }

    func select(selectable: Selectable<Data>?) {
        selectables.forEach { current in
            current.indicator.isSelected = current === selectable
        }
    }

    func getSelectedData() -> Data? {
        getAllSelectedData().first
    }
}
