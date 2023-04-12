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
    case labelLink
    case labelIndicator

    case stringSingleLine // readonly + editable
    case stringMultiLine // readonly + editable
    case readOnlyStringSingleLine

    case int // readonly + editable
    case double // readonly + editable

    // string selection e.g. using a drop-down menu or other means
    case selectString
    case chip

    case location

    case readOnlySpeciesCode
    case selectSpeciesAndImage

    case dateAndTime // readonly + editable
    case date // readonly + editable
    case timeSpan // readonly + editable
    case huntingDayAndTime // readonly + editable

    case gender
    case age

    case yesNoToggle
    case checkbox

    case instructions

    case selectDuration

    case specimen

    case harvest
    case observation

    case button
    case attachment
    case customUserInterface

    var reuseIdentifier: String {
        String(describing: self)
    }

    static func forDataFieldType<FieldId : DataFieldId>(dataFieldType: DataFieldType<FieldId>) -> DataFieldCellType {
        switch (dataFieldType) {
        case .label(let field):
            if (field.type == .caption) {
                return .labelCaption
            } else if (field.type == .error) {
                return .labelError
            } else if (field.type == .info) {
                return .labelInformation
            } else if (field.type == .link) {
                return .labelLink
            } else if (field.type == .indicator) {
                return .labelIndicator
            }

            return .placeholder
        case .string(let field):
            if (field.settings.singleLine) {
                if (field.settings.readOnly) {
                    return .readOnlyStringSingleLine
                } else {
                    return .stringSingleLine
                }
            }

            return .stringMultiLine
        case .stringList(let field):
            if (!field.settings.readOnly) {
                return .selectString
            }

            return .placeholder
        case .chip:                     return .chip
        case .boolean(let field):
            switch (field.settings.appearance) {
            case .checkbox:
                return .checkbox
            case .yesNoButtons: fallthrough
            default:
                return .yesNoToggle
            }
        case .int:                      return .int
        case .double:                   return .double
        case .location:                 return .location
        case .speciesCode(let field):
            if (field.settings.readOnly && !field.settings.showEntityImage) {
                return .readOnlySpeciesCode
            } else {
                return .selectSpeciesAndImage
            }
        case .dateAndTime:              return .dateAndTime
        case .date:                     return .date
        case .timeSpan:                 return .timeSpan
        case .huntingDayAndTime:        return .huntingDayAndTime
        case .gender:                   return .gender
        case .age:                      return .age
        case .selectDuration:           return .selectDuration
        case .specimen:                 return .specimen
        case .instructions:             return .instructions
        case .harvest:                  return .harvest
        case .observation:              return .observation
        case .button:                   return .button
        case .attachment:               return .attachment
        case .customUserInterface:      return .customUserInterface
        case .unknown:
            return .placeholder
        }
    }
}
