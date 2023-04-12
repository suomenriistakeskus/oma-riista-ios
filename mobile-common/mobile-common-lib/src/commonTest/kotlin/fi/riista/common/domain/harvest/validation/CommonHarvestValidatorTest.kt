package fi.riista.common.domain.harvest.validation

import fi.riista.common.domain.constants.Constants
import fi.riista.common.domain.constants.SpeciesCode
import fi.riista.common.domain.constants.SpeciesCodes
import fi.riista.common.domain.groupHunting.model.GroupHuntingPerson
import fi.riista.common.domain.harvest.model.CommonHarvestData
import fi.riista.common.domain.harvest.model.CommonHarvestSpecimen
import fi.riista.common.domain.harvest.model.HarvestReportingType
import fi.riista.common.domain.harvest.model.toCommonSpecimenData
import fi.riista.common.domain.harvest.ui.fields.CommonHarvestFields
import fi.riista.common.domain.model.EntityImages
import fi.riista.common.domain.model.GameAge
import fi.riista.common.domain.model.GameAntlersType
import fi.riista.common.domain.model.GameFitnessClass
import fi.riista.common.domain.model.Gender
import fi.riista.common.domain.model.Species
import fi.riista.common.domain.model.asKnownLocation
import fi.riista.common.domain.permit.model.CommonPermit
import fi.riista.common.domain.permit.model.CommonPermitSpeciesAmount
import fi.riista.common.domain.season.HarvestSeasons
import fi.riista.common.helpers.TestSpeciesResolver
import fi.riista.common.model.BackendEnum
import fi.riista.common.model.ETRMSGeoLocation
import fi.riista.common.model.GeoLocationSource
import fi.riista.common.model.LocalDate
import fi.riista.common.model.LocalDatePeriod
import fi.riista.common.model.LocalDateTime
import fi.riista.common.model.changeTime
import fi.riista.common.model.toBackendEnum
import fi.riista.common.util.MockDateTimeProvider
import fi.riista.common.util.generateMobileClientRefId
import kotlin.test.Test
import kotlin.test.assertEquals

class CommonHarvestValidatorTest {

    private val harvestFields = CommonHarvestFields(
        harvestSeasons = HarvestSeasons(),
        speciesResolver = TestSpeciesResolver.INSTANCE
    )

    @Test
    fun testValidData() {
        val context = harvestContext(
            harvest = createHarvest(),
            harvestReportingType = HarvestReportingType.SEASON,
        )

        val displayedFields = harvestFields.getFieldsToBeDisplayed(context)
        val errors = CommonHarvestValidator.validate(
            context.harvest,
            createPermit(),
            MOCK_DATE_TIME_PROVIDER,
            displayedFields,
        )

        assertEquals(0, errors.size)
    }

    @Test
    fun testNoSpecimens() {
        assertValidationError(
            expectedError = CommonHarvestValidator.Error.MISSING_SPECIMENS,
            harvest = createHarvest(specimen = null),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testDateWithinPermit() {
        val speciesCodes = listOf(
            SpeciesCodes.MOOSE_ID,
            SpeciesCodes.FALLOW_DEER_ID,
            SpeciesCodes.ROE_DEER_ID,
            SpeciesCodes.WHITE_TAILED_DEER_ID,
            SpeciesCodes.WILD_FOREST_DEER_ID,
        )
        assertNoValidationErrors(
            harvest = createHarvest(applyPermit = true),
            speciesCodes = speciesCodes,
            harvestReportingType = HarvestReportingType.PERMIT,
            permit = createPermit(speciesCodes, date = HARVEST_POINT_OF_TIME.date)
        )
    }

    @Test
    fun testDateNotWithinPermit() {
        val speciesCodes = listOf(
            SpeciesCodes.MOOSE_ID,
            SpeciesCodes.FALLOW_DEER_ID,
            SpeciesCodes.ROE_DEER_ID,
            SpeciesCodes.WHITE_TAILED_DEER_ID,
            SpeciesCodes.WILD_FOREST_DEER_ID,
        )

        assertValidationError(
            expectedError = CommonHarvestValidator.Error.DATE_NOT_WITHIN_PERMIT,
            harvest = createHarvest(applyPermit = true),
            speciesCodes = speciesCodes,
            harvestReportingType = HarvestReportingType.PERMIT,
            permit = createPermit(speciesCodes, date = HARVEST_POINT_OF_TIME.date.copy(dayOfMonth = 15))
        )
    }

    @Test
    fun testDateInFuture() {
        assertValidationError(
            expectedError = CommonHarvestValidator.Error.DATETIME_IN_FUTURE,
            harvest = createHarvest().copy(pointOfTime = HARVEST_POINT_OF_TIME.changeTime(second = 46)),
            speciesCodes = listOf(
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            ),
        )
    }

    @Test
    fun testActor() {
        assertNoValidationErrors(
            harvest = createHarvest().copy(actorInfo = GroupHuntingPerson.Unknown),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testGender_null() {
        assertValidationError(
            expectedError = CommonHarvestValidator.Error.MISSING_GENDER,
            harvest = createHarvest(createSpecimen(gender = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testGender_UNKNOWN() {
        assertValidationError(
            expectedError = CommonHarvestValidator.Error.MISSING_GENDER,
            harvest = createHarvest(createSpecimen(gender = Gender.UNKNOWN)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testAge_null() {
        assertValidationError(
            expectedError = CommonHarvestValidator.Error.MISSING_AGE,
            harvest = createHarvest(createSpecimen(age = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testAge_UNKNOWN() {
        assertValidationError(
            expectedError = CommonHarvestValidator.Error.MISSING_AGE,
            harvest = createHarvest(createSpecimen(age = GameAge.UNKNOWN)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testAlone_Deer() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(alone = null, age = GameAge.YOUNG)),
            speciesCodes = listOf(
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testNotEdible_noErrors() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(notEdible = null)),
            speciesCodes = listOf(
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
            )
        )
    }

    @Test
    fun testAntlersLost() {
        assertValidationError(
            expectedError = CommonHarvestValidator.Error.MISSING_ANTLERS_LOST,
            harvest = createHarvest(createSpecimen(antlersLost = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }


    @Test
    fun testWeightEstimated() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(weightEstimated = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testWeightMeasured() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(weightMeasured = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testFitnessClass() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(fitnessClass = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testAntlersType() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(antlersType = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testAntlersWidth() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(antlersWidth = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testAntlerPointsLeft() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(antlerPointsLeft = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testAntlerPointsRight() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(antlerPointsRight = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testAntlersGirth() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(antlersGirth = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testAntlersLength() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(antlersLength = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testAntlersInnerWidth() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(antlersInnerWidth = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    @Test
    fun testAntlerShaftWidth() {
        assertNoValidationErrors(
            harvest = createHarvest(createSpecimen(antlerShaftWidth = null)),
            speciesCodes = listOf(
                SpeciesCodes.MOOSE_ID,
                SpeciesCodes.FALLOW_DEER_ID,
                SpeciesCodes.ROE_DEER_ID,
                SpeciesCodes.WHITE_TAILED_DEER_ID,
                SpeciesCodes.WILD_FOREST_DEER_ID,
            )
        )
    }

    private fun assertValidationError(
        expectedError: CommonHarvestValidator.Error,
        harvest: CommonHarvestData = createHarvest(),
        speciesCodes: List<SpeciesCode>,
        harvestReportingType: HarvestReportingType = HarvestReportingType.SEASON,
        permit: CommonPermit? = null,
    ) {
        speciesCodes.forEach { speciesCode ->
            val errors = getValidationErrors(
                harvest = harvest.copy(species = Species.Known(speciesCode)),
                harvestReportingType = harvestReportingType,
                permit = permit
            )

            assertEquals(1, errors.size, "species: $speciesCode, errors: $errors")
            assertEquals(expectedError, errors[0], "species: $speciesCode")
        }
    }

    private fun assertNoValidationErrors(
        harvest: CommonHarvestData = createHarvest(),
        speciesCodes: List<SpeciesCode>,
        harvestReportingType: HarvestReportingType = HarvestReportingType.SEASON,
        permit: CommonPermit? = null,
    ) {
        speciesCodes.forEach { speciesCode ->
            val errors = getValidationErrors(
                harvest = harvest.copy(species = Species.Known(speciesCode)),
                harvestReportingType = harvestReportingType,
                permit = permit
            )

            assertEquals(0, errors.size, "species: $speciesCode, errors: $errors")
        }
    }

    private fun getValidationErrors(
        harvest: CommonHarvestData,
        harvestReportingType: HarvestReportingType = HarvestReportingType.SEASON,
        permit: CommonPermit? = null,
    ): List<CommonHarvestValidator.Error> {
        val context = harvestContext(harvest, harvestReportingType)

        val displayedFields = harvestFields.getFieldsToBeDisplayed(context)
        return CommonHarvestValidator.validate(
            context.harvest,
            permit,
            MOCK_DATE_TIME_PROVIDER,
            displayedFields
        )
    }

    private fun harvestContext(
        harvest: CommonHarvestData,
        harvestReportingType: HarvestReportingType,
    ) = CommonHarvestFields.Context(harvest, harvestReportingType, CommonHarvestFields.Context.Mode.EDIT)

    private fun createPermit(
        speciesCodes: List<SpeciesCode> = listOf(HARVEST_SPECIES.knownSpeciesCodeOrNull()!!),
        date: LocalDate = HARVEST_POINT_OF_TIME.date,
    ): CommonPermit {
        return CommonPermit(
            permitNumber = "Permit",
            permitType = "PermitType",
            speciesAmounts = speciesCodes.map { speciesCode ->
                CommonPermitSpeciesAmount(
                    speciesCode = speciesCode,
                    validityPeriods = listOf(
                        LocalDatePeriod(
                            beginDate = date,
                            endDate = date
                        )
                    ),
                    amount = 10.0,
                    genderRequired = false,
                    weightRequired = false,
                    ageRequired = false,
                )
            },
            available = true
        )
    }

    private fun createHarvest(
        specimen: CommonHarvestSpecimen? = createSpecimen(),
        species: Species = HARVEST_SPECIES,
        pointOfTime: LocalDateTime = HARVEST_POINT_OF_TIME,
        applyPermit: Boolean = false
    ): CommonHarvestData {
        return CommonHarvestData(
            localId = null,
            localUrl = null,
            id = null,
            rev = null,
            species = species,
            location = ETRMSGeoLocation(
                latitude = 6000,
                longitude = 8000,
                source = GeoLocationSource.MANUAL.toBackendEnum(),
                accuracy = null,
                altitude = null,
                altitudeAccuracy = null,
            ).asKnownLocation(),
            pointOfTime = pointOfTime,
            description = null,
            images = EntityImages.noImages(),
            specimens = listOfNotNull(specimen).map { it.toCommonSpecimenData() },
            amount = null,
            actorInfo = GroupHuntingPerson.Unknown,
            huntingDayId = null,
            authorInfo = null,
            canEdit = true,
            harvestSpecVersion = Constants.HARVEST_SPEC_VERSION,
            harvestReportRequired = false,
            harvestReportState = BackendEnum.create(null),
            permitNumber = "permitNumber".takeIf { applyPermit },
            permitType = "permitType".takeIf { applyPermit },
            stateAcceptedToHarvestPermit = BackendEnum.create(null),
            deerHuntingType = BackendEnum.create(null),
            deerHuntingOtherTypeDescription = null,
            mobileClientRefId = generateMobileClientRefId(),
            harvestReportDone = false,
            rejected = false,
            feedingPlace = null,
            taigaBeanGoose = null,
            greySealHuntingMethod = BackendEnum.create(null),
        )
    }

    private fun createSpecimen(
        gender: Gender? = Gender.MALE,
        age: GameAge? = GameAge.ADULT,
        antlersLost: Boolean? = false,
        notEdible: Boolean? = false,
        alone: Boolean? = false,
        weightEstimated: Double? = 100.0,
        weightMeasured: Double? = 200.0,
        fitnessClass: BackendEnum<GameFitnessClass>? = GameFitnessClass.NORMAL.toBackendEnum(),
        antlersType: BackendEnum<GameAntlersType>? = GameAntlersType.MIXED.toBackendEnum(),
        antlersWidth: Int? = 150,
        antlerPointsLeft: Int? = 25,
        antlerPointsRight: Int? = 30,
        antlersGirth: Int? = 30,
        antlersLength: Int? = 60,
        antlersInnerWidth: Int? = 18,
        antlerShaftWidth: Int? = 20,
    ): CommonHarvestSpecimen {
        return CommonHarvestSpecimen(
            gender = BackendEnum.create(gender),
            age = BackendEnum.create(age),
            antlersLost = antlersLost,
            notEdible = notEdible,
            alone = alone,
            weightEstimated = weightEstimated,
            weightMeasured = weightMeasured,
            fitnessClass = fitnessClass,
            antlersType = antlersType,
            antlersWidth = antlersWidth,
            antlerPointsLeft = antlerPointsLeft,
            antlerPointsRight = antlerPointsRight,
            antlersGirth = antlersGirth,
            antlersLength = antlersLength,
            antlersInnerWidth = antlersInnerWidth,
            antlerShaftWidth = antlerShaftWidth,
        )
    }

    companion object {
        private val HARVEST_SPECIES = Species.Known(SpeciesCodes.MOOSE_ID)
        private val HARVEST_POINT_OF_TIME = LocalDateTime(2021, 6, 14, 14, 51, 45)

        private val MOCK_DATE_TIME_PROVIDER = MockDateTimeProvider(now = HARVEST_POINT_OF_TIME)
    }
}

