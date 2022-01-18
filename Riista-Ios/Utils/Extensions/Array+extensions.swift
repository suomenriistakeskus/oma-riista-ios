import Foundation

extension Array {
    func getOrNil(index: Int) -> Element? {
        if (index >= 0 && index < count) {
            return self[index]
        }

        return nil
    }
}
