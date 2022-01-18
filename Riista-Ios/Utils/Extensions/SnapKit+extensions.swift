import Foundation
import SnapKit

enum Relation {
    case equalTo
    case greaterThanOrEqualTo
    case lessThanOrEqualTo
}

extension SnapKit.ConstraintMakerExtendable {

    /**
     * SnapKit has similar function but it is internal.
     */
    func relatedTo(_ other: ConstraintRelatableTarget, relation: Relation) -> ConstraintMakerEditable {
        switch relation {
        case .equalTo:                  return self.equalTo(other)
        case .greaterThanOrEqualTo:     return self.greaterThanOrEqualTo(other)
        case .lessThanOrEqualTo:        return self.lessThanOrEqualTo(other)
        }
    }
}
