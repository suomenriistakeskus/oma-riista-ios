import Foundation
import RiistaCommon

/**
 * A helper that is able to determine the RiistaCommon.DataField type as an enum.
 */
public enum DataFieldType<FieldId : DataFieldId> {
    /**
     * Unknown DataField type observed.
     */
    case unknown(_ field: DataField<FieldId>)

    // Known DataField types

    case string(_ field: StringField<FieldId>)
    case stringList(_ field: StringListField<FieldId>)
    case chip(_ field: ChipField<FieldId>)
    case boolean(_ field: BooleanField<FieldId>)
    case int(_ field: IntField<FieldId>)
    case double(_ field: DoubleField<FieldId>)
    case label(_ field: LabelField<FieldId>)
    case location(_ field: LocationField<FieldId>)
    case speciesCode(_ field: SpeciesField<FieldId>)
    case dateAndTime(_ field: DateAndTimeField<FieldId>)
    case date(_ field: DateField<FieldId>)
    case timeSpan(_ field: TimespanField<FieldId>)
    case huntingDayAndTime(_ field: HuntingDayAndTimeField<FieldId>)
    case gender(_ field: GenderField<FieldId>)
    case age(_ field: AgeField<FieldId>)
    case selectDuration(_ field: SelectDurationField<FieldId>)
    case instructions(_ field: InstructionsField<FieldId>)
    case specimen(_ field: SpecimenField<FieldId>)
    case harvest(_ field: HarvestField<FieldId>)
    case observation(_ field: ObservationField<FieldId>)
    case button(_ field: ButtonField<FieldId>)
    case attachment(_ field: AttachmentField<FieldId>)
    case customUserInterface(_ field: CustomUserInterfaceField<FieldId>)


    init(_ dataField: DataField<FieldId>) {
        if let field = dataField as? RiistaCommon.StringField<FieldId> {
            self = .string(field)
        } else if let field = dataField as? RiistaCommon.StringListField<FieldId> {
            self = .stringList(field)
        } else if let field = dataField as? RiistaCommon.ChipField<FieldId> {
            self = .chip(field)
        } else if let field = dataField as? RiistaCommon.BooleanField<FieldId> {
            self = .boolean(field)
        } else if let field = dataField as? RiistaCommon.IntField<FieldId> {
            self = .int(field)
        } else if let field = dataField as? RiistaCommon.DoubleField<FieldId> {
            self = .double(field)
        } else if let field = dataField as? RiistaCommon.LabelField<FieldId> {
            self = .label(field)
        } else if let field = dataField as? RiistaCommon.LocationField<FieldId> {
            self = .location(field)
        } else if let field = dataField as? RiistaCommon.SpeciesField<FieldId> {
            self = .speciesCode(field)
        } else if let field = dataField as? RiistaCommon.DateAndTimeField<FieldId> {
            self = .dateAndTime(field)
        } else if let field = dataField as? RiistaCommon.DateField<FieldId> {
            self = .date(field)
        } else if let field = dataField as? RiistaCommon.TimespanField<FieldId> {
            self = .timeSpan(field)
        } else if let field = dataField as? RiistaCommon.HuntingDayAndTimeField<FieldId> {
            self = .huntingDayAndTime(field)
        } else if let field = dataField as? RiistaCommon.GenderField<FieldId> {
            self = .gender(field)
        } else if let field = dataField as? RiistaCommon.AgeField<FieldId> {
            self = .age(field)
        } else if let field = dataField as? RiistaCommon.SelectDurationField<FieldId> {
            self = .selectDuration(field)
        } else if let field = dataField as? RiistaCommon.InstructionsField<FieldId> {
            self = .instructions(field)
        } else if let field = dataField as? RiistaCommon.SpecimenField<FieldId> {
            self = .specimen(field)
        } else if let field = dataField as? RiistaCommon.HarvestField<FieldId> {
            self = .harvest(field)
        } else if let field = dataField as? RiistaCommon.ObservationField<FieldId> {
            self = .observation(field)
        } else if let field = dataField as? RiistaCommon.ButtonField<FieldId> {
            self = .button(field)
        } else if let field = dataField as? RiistaCommon.AttachmentField<FieldId> {
            self = .attachment(field)
        } else if let field = dataField as? RiistaCommon.CustomUserInterfaceField<FieldId> {
            self = .customUserInterface(field)
        } else {
            print("Unknown DataField observed (id = \(dataField.id_))")
            self = .unknown(dataField)
        }
    }
}
