package fi.riista.common.domain.permit.model

import fi.riista.common.domain.constants.SpeciesCode
import fi.riista.common.domain.model.PermitNumber
import fi.riista.common.domain.model.Species

@kotlinx.serialization.Serializable
data class CommonPermit(
    val permitNumber: PermitNumber?,
    val permitType: String?,
    val speciesAmounts: List<CommonPermitSpeciesAmount>,

    val available: Boolean,
) {
    fun isAvailableForSpecies(species: Species): Boolean {
        return available && getSpeciesAmountFor(species) != null
    }

    fun getSpeciesAmountFor(species: Species): CommonPermitSpeciesAmount? =
        species.knownSpeciesCodeOrNull()?.let { speciesCode ->
            getSpeciesAmountFor(speciesCode)
        }

    fun getSpeciesAmountFor(speciesCode: SpeciesCode): CommonPermitSpeciesAmount? {
        return speciesAmounts.firstOrNull { it.speciesCode == speciesCode }
    }
}
