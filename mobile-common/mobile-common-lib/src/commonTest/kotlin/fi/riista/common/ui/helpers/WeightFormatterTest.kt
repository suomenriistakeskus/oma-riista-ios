package fi.riista.common.ui.helpers

import fi.riista.common.domain.constants.SpeciesCodes
import fi.riista.common.domain.model.Species
import fi.riista.common.helpers.TestStringProvider
import kotlin.test.Test
import kotlin.test.assertEquals

class WeightFormatterTest {

    private val weightFormatter = WeightFormatter(stringProvider = TestStringProvider.INSTANCE)

    @Test
    fun testDecimalsForDeer() {
        SpeciesCodes.DEER_ANIMALS.forEach { speciesCode ->
            assertEquals(0, WeightFormatter.getDecimalCount(species = Species.Known(speciesCode)))
        }
    }

    @Test
    fun testDecimalsForMoose() {
        assertEquals(0, WeightFormatter.getDecimalCount(species = Species.Known(SpeciesCodes.MOOSE_ID)))
    }

    @Test
    fun testDecimalsForOtherSpecies() {
        @Suppress("ConvertArgumentToSet")
        (ALL_SPECIES - SpeciesCodes.DEER_ANIMALS - SpeciesCodes.MOOSE_ID).forEach { speciesCode ->
            assertEquals(1, WeightFormatter.getDecimalCount(species = Species.Known(speciesCode)))
        }
    }

    @Test
    fun testOneDecimalWeightFormatting() {
        // change to different species if Bear loses decimals
        val species = Species.Known(SpeciesCodes.BEAR_ID)

        assertEquals("0.0", getFormattedWeight(0.0, species))
        assertEquals("1.0", getFormattedWeight(1.0, species))
        assertEquals("1.1", getFormattedWeight(1.1, species))
        assertEquals("20.1", getFormattedWeight(20.1, species), "20.1")
        assertEquals("20.1", getFormattedWeight(20.12, species), "20.12")
        assertEquals("20.1", getFormattedWeight(20.18, species), "20.18") // not-rounded
        assertEquals("20.1", getFormattedWeight(20.182, species), "20.182") // not-rounded
    }

    private fun getFormattedWeight(weight: Double, species: Species) = weightFormatter.formatWeight(weight, species)

    companion object {
        // from: android's species.json
        private val ALL_SPECIES = setOf(
            47348, 46615, 47503, 47507, 50106, 50386, 48089, 48251, 48250, 48537, 50336, 46549, 46542, 46587,
            47329, 47230, 47240, 47169, 47223, 47243, 47212, 200555, 47305, 47282, 47926, 47484, 47476, 47479,
            47629, 200556, 47774, 53004, 27048, 26298, 26291, 26287, 26373, 26366, 26360, 26382, 26388, 26394,
            26407, 26415, 26419, 26427, 26435, 26440, 26442, 26921, 26922, 26931, 26926, 26928, 27152, 27381,
            27649, 27911, 50114, 46564, 47180, 37178, 37166, 37122, 37142, 27750, 27759, 200535, 33117,
        )
    }
}