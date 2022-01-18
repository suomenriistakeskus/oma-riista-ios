import Foundation
import RiistaCommon

/**
 * All possible (= supported) cell types.
 */
enum DataFieldCellType {
    // placeholder for cell types that have not yet been implemented
    case placeholder

    // supported label types
    case labelCaption
    case labelInformation
    case labelError

    case string // readonly + editable
    case readOnlyStringSingleLine

    case int // readonly + editable
    case double // readonly + editable

    // string selection e.g. using a drop-down menu or other means
    case selectString

    case location

    case readOnlySpeciesCode

    case dateAndTime // readonly + editable
    case huntingDayAndTime // readonly + editable

    case gender
    case age

    case yesNoToggle

    case instructions

    case selectDuration

    case harvest
    case observation

    case customUserInterface

    var reuseIdentifier: String {
        String(describing: self)
    }

    static func forDataFieldType<FieldId : DataFieldId>(dataFieldType: DataFieldType<FieldId>) -> DataFieldCellType {
        switch (dataFieldType) {
        case .label(let field):
            if (field.type == .caption) {
                return .labelCaption
            } else if (field.type == .info) {
                return .labelInformation
            } else if (field.type == .error) {
                return .labelError
            }

            return .placeholder
        case .string(let field):
            if (field.settings.readOnly && field.settings.singleLine) {
                return .readOnlyStringSingleLine
            }

            return .string
        case .stringList(let field):
            if (!field.settings.readOnly) {
                return .selectString
            }

            return .placeholder
        case .boolean:                  return .yesNoToggle
        case .int:                      return .int
        case .double:                   return .double
        case .location:                 return .location
        case .speciesCode(let field):
            if (field.settings.readOnly) {
                return .readOnlySpeciesCode
            }

            return .placeholder
        case .dateAndTime:              return .dateAndTime
        case .huntingDayAndTime:        return .huntingDayAndTime
        case .gender:                   return .gender
        case .age:                      return .age
        case .selectDuration:           return .selectDuration
        case .instructions:             return .instructions
        case .harvest:                  return .harvest
        case .observation:              return .observation
        case .customUserInterface:      return .customUserInterface
        case .unknown:
            return .placeholder
        }
    }
}
