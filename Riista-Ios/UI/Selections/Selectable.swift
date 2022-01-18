import Foundation

/**
 * Wraps a SelectionIndicator and provides a possibility to attach data to it.
 */
class Selectable<Data> {

    let indicator: SelectionIndicator

    /**
     * A data attached if any.
     */
    var data: Data?

    convenience init(indicator: SelectionIndicator) {
        self.init(indicator: indicator, data: nil)
    }

    init(indicator: SelectionIndicator, data: Data?) {
        self.indicator = indicator
        self.data = data
    }
}
