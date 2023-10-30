import Foundation
import DropDown

typealias OnIndexClicked = (_ index: Int) -> Void

/**
 * A helper for showing a dropdown consisting of text  items from objective-c side.
 */
@objc class DropdownHelper: NSObject {

    @objc class func showDropdown(
        anchorView: UIView,
        bottomOffset: CGPoint,
        itemTitles: [String],
        onItemClicked: @escaping OnIndexClicked
    ) {
        let dropDown = DropDown()
        dropDown.anchorView = anchorView
        dropDown.direction = .bottom
        dropDown.bottomOffset = bottomOffset
        dropDown.dataSource = itemTitles
        dropDown.selectionAction = { (index: Int, _: String) in
            onItemClicked(index)
        }

        dropDown.show()
    }
}


@objc extension UIBarButtonItem {
    @objc public var plainViewCompat: UIView {
        return plainView
    }
}
