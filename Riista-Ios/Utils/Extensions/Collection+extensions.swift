import Foundation

extension Collection {
    func firstResult<T>(_ predicate: (Element) -> T?) -> T? {
        return self.lazy.compactMap(predicate).first
    }
}
