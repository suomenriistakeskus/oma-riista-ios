package fi.riista.common.helpers

import fi.riista.common.domain.constants.SpeciesCodes
import fi.riista.common.domain.model.PermitNumber
import fi.riista.common.domain.permit.PermitProvider
import fi.riista.common.domain.permit.model.CommonPermit
import fi.riista.common.domain.permit.model.CommonPermitSpeciesAmount
import fi.riista.common.resources.RR
import fi.riista.common.resources.StringProvider

@Suppress("MemberVisibilityCanBePrivate")
class TestPermitProvider: PermitProvider {

    internal var mockPermit = CommonPermit(
        permitNumber = "permitNumber",
        permitType = "mockPermit",
        speciesAmounts = listOf(
            CommonPermitSpeciesAmount(
                speciesCode = SpeciesCodes.MOOSE_ID,
                validityPeriods = listOf(),
                amount = 10.0,
                ageRequired = false,
                genderRequired = false,
                weightRequired = false,
            )
        ),
        available = true
    )

    override fun getPermit(permitNumber: PermitNumber): CommonPermit? {
        return mockPermit.takeIf { it.permitNumber == permitNumber }
    }

    companion object {
        val INSTANCE = TestPermitProvider()
    }
}
