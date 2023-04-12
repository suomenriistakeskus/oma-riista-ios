import Foundation

extension Array {
    func getOrNil(index: Int) -> Element? {
        if (index >= 0 && index < count) {
            return self[index]
        }

        return nil
    }

    func foreachAsync(
        onAllCompleted: @escaping OnCompleted,
        _ asyncElementOperation: (_ element: Element, _ onElementOperationCompleted: @escaping OnCompleted) -> Void
    ) {
        if (count == 0) {
            onAllCompleted()
            return
        }

        let incompleteOperationCount = SynchronizedInt(label: "remaining", initialValue: count)

        self.forEach { element in
            asyncElementOperation(element) {
                if (incompleteOperationCount.decrementAndGet() <= 0) {
                    onAllCompleted()
                }
            }
        }
    }
}
