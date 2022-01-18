import Foundation
import RiistaCommon


protocol ProvidesControllerWithLoadableModel: AnyObject {
    associatedtype ViewModelType: AnyObject
    associatedtype Controller: ControllerWithLoadableModel<ViewModelType>

    var controller: Controller { get }
}
