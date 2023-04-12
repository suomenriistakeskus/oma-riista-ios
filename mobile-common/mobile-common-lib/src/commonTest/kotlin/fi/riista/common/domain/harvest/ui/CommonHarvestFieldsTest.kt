package fi.riista.common.domain.harvest.ui

import fi.riista.common.domain.constants.Constants
import fi.riista.common.domain.constants.SpeciesCode
import fi.riista.common.domain.constants.SpeciesCodes
import fi.riista.common.domain.groupHunting.model.GroupHuntingPerson
import fi.riista.common.domain.harvest.model.CommonHarvestData
import fi.riista.common.domain.harvest.ui.fields.CommonHarvestFields
import fi.riista.common.domain.harvest.model.HarvestReportingType
import fi.riista.common.domain.harvest.ui.fields.CommonHarvestFields.Context.Mode
import fi.riista.common.domain.harvest.ui.fields.SpeciesSpecificHarvestFields
import fi.riista.common.domain.model.CommonSpecimenData
import fi.riista.common.domain.model.DeerHuntingType
import fi.riista.common.domain.model.EntityImages
import fi.riista.common.domain.model.GameAge
import fi.riista.common.domain.model.Gender
import fi.riista.common.domain.model.GreySealHuntingMethod
import fi.riista.common.domain.model.Species
import fi.riista.common.domain.model.asKnownLocation
import fi.riista.common.domain.model.createForTests
import fi.riista.common.domain.season.HarvestSeasons
import fi.riista.common.domain.season.model.HuntingSeason
import fi.riista.common.model.BackendEnum
import fi.riista.common.model.Date
import fi.riista.common.model.DatePeriod
import fi.riista.common.model.ETRMSGeoLocation
import fi.riista.common.model.GeoLocationSource
import fi.riista.common.model.LocalDateTime
import fi.riista.common.model.getDateWithoutYear
import fi.riista.common.ui.dataField.FieldSpecification
import fi.riista.common.ui.dataField.noRequirement
import fi.riista.common.ui.dataField.required
import fi.riista.common.ui.dataField.voluntary
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class CommonHarvestFieldsTest {

    @Test
    fun testFieldsWithoutSpeciesSpecificFields() {
        val fields = getHarvestFields()

        val context = fields.createContext(
            harvest = getHarvest(),
            mode = Mode.VIEW,
        )
        assertEquals(HarvestReportingType.BASIC, context.harvestReportingType)

        with (fields.getFieldsToBeDisplayed(context)) {
            assertEquals(
                expected = listOf(
                    CommonHarvestField.LOCATION.required(),
                    CommonHarvestField.SPECIES_CODE_AND_IMAGE.required(),
                    CommonHarvestField.DATE_AND_TIME.required(),
                    CommonHarvestField.DESCRIPTION.voluntary(),
                ),
                actual = this
            )
        }
    }

    @Test
    fun testSpeciesSpecificFieldBefore2020() {
        val fields = getHarvestFields(
            harvestFieldsPre2020 = MockSpeciesSpecificHarvestFields(
                fieldsToReturn = listOf(CommonHarvestField.GENDER.required())
            ),
        )

        val context = fields.createContext(
            harvest = getHarvest().copy(
                pointOfTime = LocalDateTime(2019, 9, 23, 14, 0, 0)
            ),
            mode = Mode.VIEW,
        )
        assertEquals(HarvestReportingType.BASIC, context.harvestReportingType)

        with (fields.getFieldsToBeDisplayed(context)) {
            assertEquals(
                expected = listOf(
                    CommonHarvestField.LOCATION.required(),
                    CommonHarvestField.SPECIES_CODE_AND_IMAGE.required(),
                    CommonHarvestField.DATE_AND_TIME.required(),
                    CommonHarvestField.GENDER.required(),
                    CommonHarvestField.DESCRIPTION.voluntary(),
                ),
                actual = this
            )
        }
    }

    @Test
    fun testSpeciesSpecificFieldAfter2020() {
        val fields = getHarvestFields(
            harvestFieldsAfter2020 = MockSpeciesSpecificHarvestFields(
                fieldsToReturn = listOf(CommonHarvestField.GENDER.required())
            )
        )

        val context = fields.createContext(
            harvest = getHarvest(),
            mode = Mode.VIEW,
        )
        assertEquals(HarvestReportingType.BASIC, context.harvestReportingType)

        with (fields.getFieldsToBeDisplayed(context)) {
            assertEquals(
                expected = listOf(
                    CommonHarvestField.LOCATION.required(),
                    CommonHarvestField.SPECIES_CODE_AND_IMAGE.required(),
                    CommonHarvestField.DATE_AND_TIME.required(),
                    CommonHarvestField.GENDER.required(),
                    CommonHarvestField.DESCRIPTION.voluntary(),
                ),
                actual = this
            )
        }
    }

    @Test
    fun testReportingTypePermit() {
        val fields = getHarvestFields()

        val context = fields.createContext(
            harvest = getHarvest().copy(
                permitNumber = "1234",
                permitType = "permit"
            ),
            mode = Mode.VIEW,
        )
        assertEquals(HarvestReportingType.PERMIT, context.harvestReportingType)

        with (fields.getFieldsToBeDisplayed(context)) {
            assertEquals(
                expected = listOf(
                    CommonHarvestField.LOCATION.required(),
                    CommonHarvestField.SPECIES_CODE_AND_IMAGE.required(),
                    CommonHarvestField.DATE_AND_TIME.required(),
                    CommonHarvestField.PERMIT_INFORMATION.noRequirement(),
                    CommonHarvestField.DESCRIPTION.voluntary(),
                ),
                actual = this
            )
        }
    }

    @Test
    fun testPermitDisplayedOutsideOfSeason() {
        CommonHarvestFields.SPECIES_REQUIRING_PERMIT_WITHOUT_SEASON.forEach { speciesCode ->
            testPermitDisplayedOutsideOfSeason(speciesCode)
        }
    }

    private fun testPermitDisplayedOutsideOfSeason(speciesCodeRequiringPermitOutsideOfSeason: SpeciesCode) {
        val harvestSeasons = HarvestSeasons()
        val month = 1
        harvestSeasons.overridesProvider.setHuntingSeasons(
            speciesCode = speciesCodeRequiringPermitOutsideOfSeason,
            huntingSeasons = listOf(
                HuntingSeason(
                    startYear = 2020,
                    endYear = null,
                    yearlySeasonPeriods = listOf(
                        DatePeriod(Date(month, 1), Date(month, 2))
                    )
                )
            )
        )

        val fields = getHarvestFields(harvestSeasons = harvestSeasons)

        val harvest = getHarvest(speciesCode = speciesCodeRequiringPermitOutsideOfSeason)
        assertTrue(harvest.pointOfTime.monthNumber != month)

        val context = fields.createContext(
            harvest = harvest,
            mode = Mode.VIEW,
        )
        // harvest reporting type should be basic as permit is not present and we're outside of season
        assertEquals(HarvestReportingType.BASIC, context.harvestReportingType, "species $speciesCodeRequiringPermitOutsideOfSeason")

        with (fields.getFieldsToBeDisplayed(context)) {
            assertEquals(
                expected = listOf(
                    CommonHarvestField.LOCATION.required(),
                    CommonHarvestField.SPECIES_CODE_AND_IMAGE.required(),
                    CommonHarvestField.DATE_AND_TIME.required(),
                    // permit number should exist as species should require permit outside of season
                    CommonHarvestField.PERMIT_INFORMATION.noRequirement(),
                    CommonHarvestField.DESCRIPTION.voluntary(),
                ),
                actual = this,
                message = "species $speciesCodeRequiringPermitOutsideOfSeason"
            )
        }
    }

    @Test
    fun testReportingTypeSeason() {
        val harvest = getHarvest()
        val harvestSeasons = HarvestSeasons()
        val seasonStart = harvest.pointOfTime.date.getDateWithoutYear()
        val seasonEnd = seasonStart.copy(dayOfMonth = seasonStart.dayOfMonth + 1)

        harvestSeasons.overridesProvider.setHuntingSeasons(
            speciesCode = SpeciesCodes.MOOSE_ID,
            huntingSeasons = listOf(
                HuntingSeason(
                    startYear = 2020,
                    endYear = null,
                    yearlySeasonPeriods = listOf(
                        DatePeriod(seasonStart, seasonEnd)
                    )
                )
            )
        )

        val fields = getHarvestFields(harvestSeasons = harvestSeasons)
        val context = fields.createContext(
            harvest = harvest,
            mode = Mode.VIEW,
        )
        assertEquals(
            HarvestReportingType.SEASON,
            context.harvestReportingType
        )

        with (fields.getFieldsToBeDisplayed(context)) {
            assertEquals(
                expected = listOf(
                    CommonHarvestField.LOCATION.required(),
                    CommonHarvestField.SPECIES_CODE_AND_IMAGE.required(),
                    CommonHarvestField.DATE_AND_TIME.required(),
                    CommonHarvestField.DESCRIPTION.voluntary(),
                ),
                actual = this
            )
        }
    }

    companion object {

        internal fun getHarvestFields(
            speciesCode: SpeciesCode = SpeciesCodes.MOOSE_ID,
            harvestSeasons: HarvestSeasons = HarvestSeasons(),
            harvestFieldsPre2020: SpeciesSpecificHarvestFields = MockSpeciesSpecificHarvestFields(speciesCode),
            harvestFieldsAfter2020: SpeciesSpecificHarvestFields = MockSpeciesSpecificHarvestFields(speciesCode)
        ) = CommonHarvestFields(harvestSeasons, harvestFieldsPre2020, harvestFieldsAfter2020)

        internal fun getHarvest(
            speciesCode: SpeciesCode = SpeciesCodes.MOOSE_ID,
            gender: Gender? = null,
            age: GameAge? = null,
            greySealHuntingMethod: GreySealHuntingMethod? = null,
            antlersLost: Boolean? = null,
        ) =
            CommonHarvestData(
                localId = null,
                localUrl = null,
                id = 1,
                rev = 2,
                species = Species.Known(speciesCode),
                location = ETRMSGeoLocation(
                    30, 20, BackendEnum.create(GeoLocationSource.GPS_DEVICE),
                    40.0, 50.0, 60.0
                ).asKnownLocation(),
                pointOfTime = LocalDateTime(2022, 9, 23, 14, 0, 0),
                description = "description",
                canEdit = true,
                images = EntityImages.noImages(),
                specimens = listOf(
                    CommonSpecimenData.createForTests(
                        gender = BackendEnum.create(gender),
                        age = BackendEnum.create(age),
                        antlersLost = antlersLost,
                    )
                ),
                amount = 1,
                huntingDayId = null,
                authorInfo = null,
                actorInfo = GroupHuntingPerson.Unknown,
                harvestSpecVersion = Constants.HARVEST_SPEC_VERSION,
                harvestReportRequired = false,
                harvestReportState = BackendEnum.create(null),
                permitNumber = null,
                permitType = null,
                stateAcceptedToHarvestPermit = BackendEnum.create(null),
                deerHuntingType = BackendEnum.create(DeerHuntingType.OTHER),
                deerHuntingOtherTypeDescription = "ritsalla ammuttu",
                mobileClientRefId = 99,
                harvestReportDone = false,
                rejected = false,
                feedingPlace = null,
                taigaBeanGoose = null,
                greySealHuntingMethod = BackendEnum.create(greySealHuntingMethod),
            )
    }
}

private class MockSpeciesSpecificHarvestFields(
    val speciesCode: SpeciesCode = SpeciesCodes.MOOSE_ID,
    val fieldsToReturn: List<FieldSpecification<CommonHarvestField>>? = null
): SpeciesSpecificHarvestFields {
    override fun getSpeciesSpecificFields(context: CommonHarvestFields.Context): List<FieldSpecification<CommonHarvestField>>? {
        return fieldsToReturn.takeIf { context.speciesCode == speciesCode }
    }
}