import Foundation

// provides similar functionality as what apply() does in Kotlin
protocol HasApply { }

extension HasApply {
    @discardableResult
    func apply(_ closure: (Self) -> ()) -> Self {
        closure(self)
        return self
    }
}


extension NSObject: HasApply {}
