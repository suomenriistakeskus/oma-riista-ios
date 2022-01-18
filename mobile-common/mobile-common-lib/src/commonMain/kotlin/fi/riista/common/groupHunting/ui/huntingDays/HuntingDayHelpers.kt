package fi.riista.common.groupHunting.ui.huntingDays

import fi.riista.common.groupHunting.model.GroupHuntingDay
import fi.riista.common.model.SpeciesCode
import fi.riista.common.model.isDeer
import fi.riista.common.resources.RR

fun List<GroupHuntingDay>?.selectNoHuntingDaysText(
    speciesCode: SpeciesCode,
    canCreateHuntingDay: Boolean,
): RR.string? {
    return if (isNullOrEmpty()) {
        when {
            speciesCode.isDeer() -> RR.string.group_hunting_message_no_hunting_days_deer
            canCreateHuntingDay -> RR.string.group_hunting_message_no_hunting_days_but_can_create
            else -> RR.string.group_hunting_message_no_hunting_days
        }
    } else {
        null
    }
}