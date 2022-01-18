import Foundation


public typealias ConditionCheck = () -> Bool

public protocol WithConditionals { }

extension WithConditionals where Self: Any {
    @inlinable
    @discardableResult
    public func when(_ condition: ConditionCheck, block: (inout Self) -> Void) -> Self {
        if (condition()) {
            var myself = self
            block(&myself)
        }

        return self
    }
}

//  uncomment / test if needed in the future. Commented out for now as not yet needed.
/*
@inlinable
public func not(_ condition: @escaping ConditionCheck) -> ConditionCheck {
    return {
        return !condition()
    }
}

@inlinable
public func all(_ conditions: [ConditionCheck]) -> ConditionCheck {
    return {
        for condition in conditions {
            if (!condition()) {
                return false
            }
        }
        return true
    }
}
*/
