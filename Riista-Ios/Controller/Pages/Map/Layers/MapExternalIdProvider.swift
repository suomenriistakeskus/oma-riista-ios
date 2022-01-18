import Foundation

protocol MapExternalIdProvider: AnyObject {
    func getMapExternalId() -> String?
}
