package fi.riista.common.groupHunting.model

import fi.riista.common.model.*

data class HuntingGroupPermit(
    val permitNumber: PermitNumber,

    /**
     * The date periods describing when the hunting is allowed and when the hunting
     * days are allowed.
     */
    val validityPeriods: List<LocalDatePeriod>
) {
    val earliestDate: LocalDate? by lazy {
        validityPeriods.minOfOrNull { it.beginDate }
    }

    val lastDate: LocalDate? by lazy {
        validityPeriods.maxOfOrNull { it.endDate }
    }
}

fun LocalDate.isWithinPermit(permit: HuntingGroupPermit): Boolean {
    // assume within permit if validityPeriods has not been specified
    return permit.validityPeriods.isEmpty() ||
            isWithinPeriods(permit.validityPeriods)
}

fun LocalDate.coerceInPermitValidityPeriods(permit: HuntingGroupPermit): LocalDate {
    // easy / fast path, date already within validity periods
    if (isWithinPermit(permit)) {
        return this
    }

    // already checked in isWithinPermit but let's make sure just in case implementation changes
    if (permit.validityPeriods.isEmpty()) {
        return this
    }

    val selectedPeriod = permit.validityPeriods.sortedBy { it.endDate }.findLast { this > it.endDate }
                ?: permit.validityPeriods.sortedBy { it.beginDate }.find { this < it.beginDate }

    return if (selectedPeriod != null) {
        coerceIn(selectedPeriod)
    } else {
        this
    }
}

fun LocalDatePeriod.isWithinPermit(permit: HuntingGroupPermit): Boolean {
    // assume within permit if validityPeriods has not been specified
    return permit.validityPeriods.isEmpty() ||
            permit.validityPeriods.find { isWithinPeriod(it) } != null
}