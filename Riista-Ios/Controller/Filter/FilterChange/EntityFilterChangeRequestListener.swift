import Foundation

protocol EntityFilterChangeRequestListener: AnyObject {
    func onFilterChangeRequested(filter: EntityFilter)
}
