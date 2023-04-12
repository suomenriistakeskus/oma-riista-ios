import Foundation

protocol EntityDataSourceListener: AnyObject {
    // called e.g. after data data source data has been updated
    func onDataSourceDataUpdated(for entityType: FilterableEntityType)
}
