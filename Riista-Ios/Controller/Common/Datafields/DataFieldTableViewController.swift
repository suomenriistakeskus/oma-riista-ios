import Foundation
import RiistaCommon
import DifferenceKit


/**
 * A holder for DataFields in order to provide Differentiable implementation.
 *
 * Extending the DataField with Differentiable protocol support was the first attempt but
 * it seems that extensions cannot access generic parameters (i.e. FieldId) at runtime and
 * thus a class was needed.
 */
class DataFieldHolder<FieldId: DataFieldId>: Differentiable {
    var differenceIdentifier: Int {
        get {
            Int(dataField.id_.toInt())
        }
    }

    private(set) var dataField: DataField<FieldId>

    init(dataField: DataField<FieldId>) {
        self.dataField = dataField
    }

    func replaceDataField(newField: DataField<FieldId>) {
        dataField = newField
    }

    func isHoldingDataField(field: DataField<FieldId>) -> Bool {
        return dataField.isSame(other: field)
    }

    func isContentEqual(to source: DataFieldHolder<FieldId>) -> Bool {
        return dataField.isContentSame(other: source.dataField)
    }
}

/**
 * A controller for a UITableView which is used for displaying datafields.
 */
class DataFieldTableViewController<FieldId : DataFieldId>: NSObject, UITableViewDelegate, UITableViewDataSource {
    private(set) var tableView: UITableView? = nil {
        didSet {
            if let tableView = tableView as? TableView {
                tableViewSupportsPendingUpdates = true
                tableView.onWindowSet = { [weak self] in
                    self?.applyPendingDataFields()
                }
            } else {
                tableViewSupportsPendingUpdates = false
            }
        }
    }

    /**
     * Does the current tableview support pending updates? Currently only `TableView` instances
     * support pending updates as they are able to report when their `window` has been set.
     */
    private var tableViewSupportsPendingUpdates: Bool = false


    private var dataFieldHolders: [DataFieldHolder<FieldId>] = []
    private var pendingDataFields: [DataField<FieldId>]? = nil

    private let cellFactories = DefaultDataFieldCellFactories<FieldId>()

    func setTableView(_ tableView: UITableView) {
        self.tableView = tableView

        tableView.delegate = self
        tableView.dataSource = self
        cellFactories.registerCellTypes(to: tableView)
    }

    func setDataFields(dataFields: [DataField<FieldId>]) {
        if (canUpdateDataFields() || !tableViewSupportsPendingUpdates) {
            updateDataFields(dataFields: dataFields)
        } else {
            pendingDataFields = dataFields
        }
    }

    private func canUpdateDataFields() -> Bool {
        // tableview reload based on StagedChangeset will perform full reload if
        // tableview doesn't have valid window i.e. implementation begins with
        //
        //   if case .none = window, let data = stagedChangeset.last?.data {
        //     setData(data)
        //     return reloadData()
        //   }
        //
        // Don't allow updating datafields unless there is a window. This prevents full
        // reload when tableview contents are being updated during viewWillAppear. Full
        // reload would cause all cells to be bound again instead of rebinding just those
        // cells that have changed
        return tableView?.window != nil
    }

    private func applyPendingDataFields() {
        if let dataFields = pendingDataFields {
            setDataFields(dataFields: dataFields)
        }
    }

    private func updateDataFields(dataFields: [DataField<FieldId>]) {
        // ensure same datafields won't be applied more than once
        pendingDataFields = nil

        let customCellFactory = cellFactories.getFactoryOrNil(cellType: .customUserInterface)
        let newDataFieldHolders = dataFields
            .filter { dataField in
                if (!(dataField is CustomUserInterfaceField<FieldId>)) {
                    return true
                } else if let cellFactory = customCellFactory {
                    return cellFactory.canCreateCell(for: dataField)
                } else {
                    print("\n*******\nA CustomUserInterfaceField observed. Did you forget to register your own" +
                            " cell factory that supports custom fields with id = '\(dataField.id_)'?\n*******\n")
                    return false
                }
            }
            .map { DataFieldHolder(dataField: $0) }

        if let tableView = tableView {
            // Try to rebind to existing cells as the first step. This allows updating cell
            // without UITableView of knowing it. If we used the default tableview update
            // method (i.e. reloadRow), the tableview would
            //   1. dequeue another cell for displaying the new data
            //   2. bind the data field to that cell
            //   3. switch to using the new cell with e.g. fade animation
            rebindFieldsToExistingCells(tableView: tableView, dataFields: dataFields)

            let stagedChangeSet = StagedChangeset(source: self.dataFieldHolders, target: newDataFieldHolders)
            tableView.reload(using: stagedChangeSet, with: .fade) { newDataFieldHolders in
                self.dataFieldHolders = newDataFieldHolders
            }

            tableView.beginUpdates()
            tableView.endUpdates()
        } else {
            self.dataFieldHolders = newDataFieldHolders
            print("Did you forget to set tableView?")
        }
    }

    /**
     * Attempts to rebind data fields to existing, visible cells.
     *
     * Will update backing data of the updated cells (i.e. DataFields held by `dataFieldHolders`) if rebind succeeds.
     * Will only update cell if data has been changed.
     */
    private func rebindFieldsToExistingCells(tableView: UITableView, dataFields: [DataField<FieldId>]) {
        tableView.visibleCells.forEach { cell in
            guard let dataFieldCell = cell as? DataFieldCell<FieldId> else {
                print("Cell \(String(describing: cell.reuseIdentifier)) not DataFieldCell!")
                return
            }

            guard let dataField = dataFields.first(where: { dataField in
                if (dataFieldCell.isBound(field: dataField)) {
                    // make sure cell types match. It is possible that cell type changes for the datafield
                    // - for example it is possible that first information label is being displayed while
                    //   entering/fetching the data. It may be replaced by an error label (same field id!)
                    //   if invalid data is entered / data fetch fails.
                    let cellType = DataFieldCellType.forDataFieldType(dataFieldType: DataFieldType(dataField))
                    return dataFieldCell.cellType == cellType
                } else {
                    return false
                }
            }) else {
                print("No datafield found for cell \(String(describing: cell.reuseIdentifier))")
                return
            }

            rebindCellData(dataFieldCell: dataFieldCell, dataField: dataField)
        }
    }

    /**
     * Attempts to rebind `dataField` to the given `dataFieldCell`. Will only update cell if data has been changed.
     *
     * Will update backing data of the cell (i.e. DataFields held by `dataFieldHolders`) if rebind succeeds.
     */
    private func rebindCellData(dataFieldCell: DataFieldCell<FieldId>, dataField: DataField<FieldId>) {
        guard let dataFieldHolder = dataFieldHolders.first(where: { holder in
            holder.isHoldingDataField(field: dataField)
        }) else {
            // rebind wouldn't help much as cell would be updated any way if we cannot
            // update the backing data (in DataFieldHolder)
            print("Cannot rebind cell, no existing DataFieldHolder for cell data!")
            return
        }

        if (dataFieldCell.rebindIfChanged(field: dataField)) {
            // update the datafield in the datafield holder. This ensures that the backing
            // data for the tableview matches what is being displayed in the UI.
            dataFieldHolder.replaceDataField(newField: dataField)
        }
    }

    func addCellFactory(_ factory: DataFieldCellFactory<FieldId>) {
        cellFactories.addCellFactory(factory: factory)

        if let tableView = tableView {
            factory.registerCellType(to: tableView)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataFieldHolders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataField = dataFieldHolders[indexPath.row].dataField
        let cellType = DataFieldCellType.forDataFieldType(dataFieldType: DataFieldType(dataField))

        let factory = cellFactories.getFactory(cellType: cellType)
        let cell = factory.createCell(for: tableView, indexPath: indexPath, dataField: dataField)

        cell.tableView = tableView as? TableView
        cell.bind(field: dataField)

        return cell
    }
}

extension DataFieldTableViewController where FieldId: DataFieldId {
    func addDefaultCellFactories(
        navigationControllerProvider: ProvidesNavigationController? = nil,
        huntingGroupProvider: HuntingGroupTargetProvider? = nil,
        locationEventDispatcher: LocationEventDispatcher? = nil,
        stringWithIdEventDispatcher: StringWithIdEventDispatcher? = nil,
        stringClickEventDispatcher: StringWithIdClickEventDispatcher? = nil,
        stringEventDispatcher: StringEventDispatcher? = nil,
        booleanEventDispatcher: BooleanEventDispatcher? = nil,
        intEventDispatcher: IntEventDispatcher? = nil,
        doubleEventDispatcher: DoubleEventDispatcher? = nil,
        localDateTimeEventDispacter: LocalDateTimeEventDispatcher? = nil,
        huntingDayEventDispacter: HuntingDayIdEventDispatcher? = nil,
        localDateEventDispatcher: LocalDateEventDispatcher? = nil,
        localTimeEventDispatcher: LocalTimeEventDispatcher? = nil,
        genderEventDispatcher: GenderEventDispatcher? = nil,
        ageEventDispatcher: AgeEventDispatcher? = nil,
        hoursAndMinutesEventDispatcher: HoursAndMinutesEventDispatcher? = nil,
        harvestClickHandler: HarvestFieldCellClickHandler? = nil,
        observationClickHandler: ObservationFieldCellClickHandler? = nil,
        mapExternalIdProvider: MapExternalIdProvider? = nil,
        attachmentClickListener: AttachmentFieldAction<FieldId>? = nil,
        attachmentRemoveListener: AttachmentFieldAction<FieldId>? = nil,
        attachmentStatusProvider: AttachmentFieldStatusProvider? = nil,
        buttonClickHandler: OnButtonClicked<FieldId>? = nil,
        specimenLauncher: SpecimenLauncher<FieldId>? = nil,
        speciesEventDispatcher: SpeciesEventDispatcher? = nil,
        speciesImageClickListener: SpeciesImageClickListener<FieldId>? = nil
    ) {
        let factories: [DataFieldCellFactory<FieldId>?] = [
            // explicitly DO NOT ADD a default factory for custom user interface
            // as that allows determining whether there is a valid factory for it added
            // by the actual viewcontroller
            CaptionLabelFieldCell<FieldId>.Factory<FieldId>(),
            InformationLabelFieldCell<FieldId>.Factory<FieldId>(),
            ErrorLabelFieldCell<FieldId>.Factory<FieldId>(),
            ReadOnlySingleLineStringFieldCell<FieldId>.Factory<FieldId>(),
            SingleLineStringFieldCell<FieldId>.Factory<FieldId>(eventDispatcher: stringEventDispatcher),
            MultiLineStringFieldCell<FieldId>.Factory<FieldId>(eventDispatcher: stringEventDispatcher),
            YesNoBooleanFieldCell<FieldId>.Factory<FieldId>(eventDispatcher: booleanEventDispatcher),
            CheckboxBooleanFieldCell<FieldId>.Factory<FieldId>(eventDispatcher: booleanEventDispatcher),
            IntFieldCell<FieldId>.Factory<FieldId>(eventDispatcher: intEventDispatcher),
            DoubleFieldCell<FieldId>.Factory<FieldId>(eventDispatcher: doubleEventDispatcher),
            LocationFieldCell<FieldId>.Factory<FieldId>(
                navigationControllerProvider: navigationControllerProvider,
                locationEventDispatcher: locationEventDispatcher,
                mapExternalIdProvider: mapExternalIdProvider
            ),
            ReadOnlySpeciesFieldCell<FieldId>.Factory<FieldId>(),
            SelectSpeciesAndImageFieldCell<FieldId>.Factory<FieldId>(
                navigationControllerProvider: navigationControllerProvider,
                speciesEventDispatcher: speciesEventDispatcher,
                speciesImageClickListener: speciesImageClickListener
            ),
            DateAndTimeFieldCell<FieldId>.Factory<FieldId>(
                navigationControllerProvider: navigationControllerProvider,
                eventDispatcher: localDateTimeEventDispacter
            ),
            DateCell<FieldId>.Factory<FieldId>(
                navigationControllerProvider: navigationControllerProvider,
                eventDispatcher: localDateEventDispatcher
            ),
            TimeSpanCell<FieldId>.Factory<FieldId>(
                navigationControllerProvider: navigationControllerProvider,
                eventDispatcher: localTimeEventDispatcher
            ),
            HuntingDayAndTimeFieldCell<FieldId>.Factory<FieldId>(
                navigationControllerProvider: navigationControllerProvider,
                huntingGroupProvider: huntingGroupProvider,
                huntingDayEventDispatcher: huntingDayEventDispacter,
                localTimeEventDispatcher: localTimeEventDispatcher
            ),
            GenderFieldCell<FieldId>.Factory<FieldId>(eventDispatcher: genderEventDispatcher),
            AgeFieldCell<FieldId>.Factory<FieldId>(eventDispatcher: ageEventDispatcher),
            InstructionsFieldCell<FieldId>.Factory<FieldId>(navigationControllerProvider: navigationControllerProvider),
            HarvestFieldCell<FieldId>.Factory<FieldId>(harvestCellClickHandler: harvestClickHandler),
            ObservationFieldCell<FieldId>.Factory<FieldId>(observationCellClickHandler: observationClickHandler),
            ButtonFieldCell<FieldId>.Factory<FieldId>(clickHandler: buttonClickHandler),
            AttachmentFieldCell<FieldId>.Factory<FieldId>(
                clickListener: attachmentClickListener,
                removeListener: attachmentRemoveListener,
                attachmentStatusProvider: attachmentStatusProvider
            ),

            SelectStringFieldCell<FieldId>.Factory<FieldId>(
                navigationControllerProvider: navigationControllerProvider,
                eventDispatcher: stringWithIdEventDispatcher
            ),
            SelectDurationFieldCell<FieldId>.Factory<FieldId>(
                navigationControllerProvider: navigationControllerProvider,
                eventDispatcher: hoursAndMinutesEventDispatcher
            ),
            ChipFieldCell<FieldId>.Factory<FieldId>(
                eventDispatcher: stringClickEventDispatcher
            ),
            SpecimenFieldCell<FieldId>.Factory<FieldId>(
                specimenLauncher: specimenLauncher
            )
        ]

        factories.forEach { factory in
            if let factory = factory {
                addCellFactory(factory)
            }
        }
    }
}
