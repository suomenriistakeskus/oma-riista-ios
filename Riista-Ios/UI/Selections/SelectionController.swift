import Foundation


/**
 * A separate protocol for SelectionController in order to restrict what functionality SelectionIndicators are able to utilize
 */
protocol SelectionController {
    func onSelectableClicked(indicator: SelectionIndicator)
}

class SelectionControllerWithData<Data>: SelectionController {

    var isEnabled: Bool = true {
        didSet {
            selectables.forEach { selectable in
                selectable.indicator.isEnabled = isEnabled
            }
        }
    }

    /**
     * All selectables added with addSelectable
     */
    private(set) var selectables: [Selectable<Data>] = []

    func addSelectable(_ indicator: SelectionIndicator, data: Data? = nil) {
        let selectable = Selectable(indicator: indicator, data: data)
        indicator.controller = self
        selectables.append(selectable)
    }

    func onSelectableClicked(indicator: SelectionIndicator) {
        fatalError("SelectionController needs to be subclassed!")
    }

    func getAllSelectedData() -> [Data] {
        selectables
            .filter { selectable in
                selectable.indicator.isSelected && selectable.data != nil
            }
            .map { $0.data! }
    }

    func deselectAll() {
        selectables.forEach { selectable in
            selectable.indicator.isSelected = false
        }
    }
}
