import Foundation
import RiistaCommon

protocol HuntingGroupTargetProvider: AnyObject {
    var huntingGroupTarget: IdentifiesHuntingGroup { get }
}
