package fi.riista.common.model

import fi.riista.common.resources.LocalizableEnum
import fi.riista.common.resources.RR

enum class DeerHuntingType(
    override val rawBackendEnumValue: String,
    override val resourcesStringId: RR.string,
) : RepresentsBackendEnum, LocalizableEnum {
    STAND_HUNTING("STAND_HUNTING", RR.string.deer_hunting_type_stand_hunting),
    DOG_HUNTING("DOG_HUNTING", RR.string.deer_hunting_type_dog_hunting),
    OTHER("OTHER", RR.string.deer_hunting_type_other),
    ;
}
