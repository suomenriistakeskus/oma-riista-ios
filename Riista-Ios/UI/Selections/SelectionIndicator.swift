import Foundation


// SelectionController at the bottom of the file

protocol SelectionIndicator: AnyObject {
    /**
     * Is the Selectable currently selected or not? (should probably match UIControl.isSelected)
     */
    var isSelected: Bool { get set }

    /**
     * Can the Selectable be selected? (should probably match UIControl.isEnabled)
     */
    var isEnabled: Bool { get set }

    /**
     * The controller to which click event should be reported.
     */
    var controller: SelectionController? { get set }
}
