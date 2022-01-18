import Foundation
import DropDown

class DropdownItemProvider {
    private var items: [DropdownItem] = []

    var onItemsChanged: OnChanged?

    var visibleItems: [DropdownItem] {
        items.filter { !$0.hidden }
    }

    func addItem(_ item: DropdownItem) {
        items.append(item)
        onItemsChanged?()
    }

    func show(id: Int) {
        setItemVisibility(id: id, visible: true)
    }

    func hide(id: Int) {
        setItemVisibility(id: id, visible: false)
    }

    func onItemSelected(index: Int) {
        if let item = visibleItems.getOrNil(index: index) {
            item.onClicked()
        }
    }

    func setItemVisibility(id: Int, visible: Bool) {
        if let item = items.first(where: { $0.id == id }) {
            let hidden = !visible
            if (item.hidden != hidden) {
                item.hidden = hidden
                onItemsChanged?()
            }
        }
    }
}

extension DropDown {
    func setDataSource(using provider: DropdownItemProvider) {
        self.dataSource = provider.visibleItems.map { $0.title }
    }
}
