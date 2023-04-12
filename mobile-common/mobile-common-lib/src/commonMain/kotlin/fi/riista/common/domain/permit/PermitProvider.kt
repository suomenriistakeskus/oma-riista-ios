package fi.riista.common.domain.permit

import fi.riista.common.domain.harvest.model.CommonHarvestData
import fi.riista.common.domain.model.PermitNumber
import fi.riista.common.domain.permit.model.CommonPermit

interface PermitProvider {
    fun getPermit(permitNumber: PermitNumber): CommonPermit?
}

internal fun PermitProvider.getPermit(harvest: CommonHarvestData): CommonPermit? =
    harvest.permitNumber?.let { permitNumber ->
        getPermit(permitNumber)
    }
