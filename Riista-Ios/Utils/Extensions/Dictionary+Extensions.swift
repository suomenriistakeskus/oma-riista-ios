import Foundation

extension Dictionary where Value: Equatable {

    func key(forValue value: Value) -> Key? {
        return first(where: { $0.value == value })?.key
    }
}
