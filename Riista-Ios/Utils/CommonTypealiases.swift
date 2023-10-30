import Foundation


typealias OnCompleted = () -> Void
typealias OnCompletedWithStatus = (_ success: Bool) -> Void
typealias OnCompletedWithStatusAndError = (_ success: Bool, _ error: Error?) -> Void
typealias OnCompletedWithError = (_ error: Error?) -> Void
typealias OnCompletedWithResultAndError<Result : AnyObject> = (_ result: Result?, _ error: Error?) -> Void
typealias OnClicked = () -> Void
typealias OnChanged = () -> Void
typealias OnTextChanged = (_ text: String) -> Void
typealias OnValueChanged<T> = (_ value: T) -> Void
