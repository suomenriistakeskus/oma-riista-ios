import Foundation

class DropdownItem {
    let id: Int
    var title: String
    var hidden: Bool
    var onClicked: OnClicked

    init(id: Int, title: String, hidden: Bool, onClicked: @escaping OnClicked) {
        self.id = id
        self.title = title
        self.hidden = hidden
        self.onClicked = onClicked
    }
}
