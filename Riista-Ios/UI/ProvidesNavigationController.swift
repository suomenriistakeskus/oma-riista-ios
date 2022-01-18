import Foundation

@objc protocol ProvidesNavigationController: AnyObject {
    var navigationController: UINavigationController? { get }
}
