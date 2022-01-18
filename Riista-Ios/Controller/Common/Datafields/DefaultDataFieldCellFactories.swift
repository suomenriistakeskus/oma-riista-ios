import Foundation
import RiistaCommon

class DefaultDataFieldCellFactories<FieldId : DataFieldId> {
    private var cellFactories: [DataFieldCellFactory<FieldId>] = []
    private var fallbackFactory: DataFieldCellFactory<FieldId> = PlaceholderDataFieldCell<FieldId>.Factory<FieldId>()

    func addCellFactory(factory: DataFieldCellFactory<FieldId>) {
        // allow replacing fallback factory
        if (factory.cellType == fallbackFactory.cellType) {
            print("Replacing fallback cell factory (cell type \(factory.cellType))!")
            fallbackFactory = factory
        } else {
            cellFactories.removeAll { candidate in
                if (candidate.cellType == factory.cellType) {
                    print("Removing previous cell factory for type \(factory.cellType)")
                    return true
                }
                return false
            }

            print("Adding a cell factory for type \(factory.cellType)")
            cellFactories.append(factory)
        }
    }

    func registerCellTypes(to tableView: UITableView) {
        cellFactories.forEach { factory in
            factory.registerCellType(to: tableView)
        }
        fallbackFactory.registerCellType(to: tableView)
    }

    /**
     * Gets the factory for given cellType if found. Returns the fallbackFactory if none is found.
     */
    func getFactory(cellType: DataFieldCellType) -> DataFieldCellFactory<FieldId> {
        return getFactoryOrNil(cellType: cellType) ?? fallbackFactory
    }

    func getFactoryOrNil(cellType: DataFieldCellType) -> DataFieldCellFactory<FieldId>? {
        let factory = cellFactories.first { factory in
            factory.cellType == cellType
        }

        return factory
    }
}
