import Foundation

extension Optional {
    @discardableResult
    @inlinable public func mapWith<T, U>(_ other: T?, _ transform: (Wrapped, T) throws -> U) rethrows -> U? {
        switch self {
        case .none:
            return nil
        case .some(let wrapped):
            if let other = other {
                let result = try transform(wrapped, other)
                return result
            }
            return nil
        }
    }
}
