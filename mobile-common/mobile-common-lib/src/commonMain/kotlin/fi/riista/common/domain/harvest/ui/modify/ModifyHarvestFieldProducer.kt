package fi.riista.common.domain.harvest.ui.modify

import fi.riista.common.domain.constants.SpeciesCodes
import fi.riista.common.domain.constants.SpeciesConstants
import fi.riista.common.domain.harvest.model.CommonHarvestData
import fi.riista.common.domain.harvest.model.HarvestConstants
import fi.riista.common.domain.harvest.model.HarvestReportingType
import fi.riista.common.domain.harvest.ui.CommonHarvestField
import fi.riista.common.domain.harvest.ui.common.HarvestSpecimenFieldProducer
import fi.riista.common.domain.model.DeerHuntingType
import fi.riista.common.domain.model.GameAge
import fi.riista.common.domain.model.GameAntlersType
import fi.riista.common.domain.model.GameFitnessClass
import fi.riista.common.domain.model.Gender
import fi.riista.common.domain.model.GreySealHuntingMethod
import fi.riista.common.domain.model.Species
import fi.riista.common.domain.permit.PermitProvider
import fi.riista.common.model.BackendEnum
import fi.riista.common.resources.RR
import fi.riista.common.resources.StringProvider
import fi.riista.common.ui.dataField.AgeField
import fi.riista.common.ui.dataField.BooleanField
import fi.riista.common.ui.dataField.DataField
import fi.riista.common.ui.dataField.DateAndTimeField
import fi.riista.common.ui.dataField.DoubleField
import fi.riista.common.ui.dataField.EnumStringListFieldFactory
import fi.riista.common.ui.dataField.FieldSpecification
import fi.riista.common.ui.dataField.GenderField
import fi.riista.common.ui.dataField.HuntingDayAndTimeField
import fi.riista.common.ui.dataField.InstructionsField
import fi.riista.common.ui.dataField.IntField
import fi.riista.common.ui.dataField.LabelField
import fi.riista.common.ui.dataField.LocationField
import fi.riista.common.ui.dataField.Padding
import fi.riista.common.ui.dataField.SpeciesField
import fi.riista.common.ui.dataField.SpecimenField
import fi.riista.common.ui.dataField.StringField
import fi.riista.common.ui.dataField.StringListField
import fi.riista.common.ui.helpers.WeightFormatter
import fi.riista.common.util.LocalDateTimeProvider


internal open class ModifyHarvestFieldProducer(
    private val canChangeSpecies: Boolean,
    private val permitProvider: PermitProvider?,
    protected val stringProvider: StringProvider,
    private val currentDateTimeProvider: LocalDateTimeProvider?,
) {
    private val specimenFieldProducer = HarvestSpecimenFieldProducer(
        stringProvider = stringProvider
    )

    internal val selectableHarvestSpecies: SpeciesField.SelectableSpecies = SpeciesField.SelectableSpecies.All

    private val deerHuntingTypeFieldFactory = EnumStringListFieldFactory.create<DeerHuntingType>(stringProvider)
    private val antlersTypeFieldFactory = EnumStringListFieldFactory.create<GameAntlersType>(stringProvider)
    private val fitnessClassFieldFactory = EnumStringListFieldFactory.create<GameFitnessClass>(stringProvider)
    private val greySealHuntingMethodFactory = EnumStringListFieldFactory.create<GreySealHuntingMethod>(stringProvider)

    fun createField(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData,
        harvestReportingType: HarvestReportingType,
    ) : DataField<CommonHarvestField>? {
        return when (fieldSpecification.fieldId) {
            CommonHarvestField.SPECIES_CODE -> speciesCode(fieldSpecification, harvest, showEntityImage = false)
            CommonHarvestField.SPECIES_CODE_AND_IMAGE -> speciesCode(fieldSpecification, harvest, showEntityImage = true)
            CommonHarvestField.DATE_AND_TIME -> dateAndTime(fieldSpecification, harvest)
            CommonHarvestField.ERROR_DATE_NOT_WITHIN_PERMIT -> errorDateNotWithinPermit(fieldSpecification)
            CommonHarvestField.ERROR_DATETIME_IN_FUTURE -> errorDatetimeInFuture(fieldSpecification)
            CommonHarvestField.HUNTING_DAY_AND_TIME -> huntingDayAndTime(fieldSpecification, harvest)
            CommonHarvestField.ERROR_TIME_NOT_WITHIN_HUNTING_DAY -> errorTimeNotWithinHuntingDay(fieldSpecification)
            CommonHarvestField.LOCATION -> location(fieldSpecification, harvest)
            CommonHarvestField.SPECIMEN_AMOUNT -> specimenAmount(fieldSpecification, harvest)
            CommonHarvestField.SPECIMENS -> specimens(fieldSpecification, harvest, harvestReportingType)
            CommonHarvestField.HEADLINE_SHOOTER -> shooter(fieldSpecification)
            CommonHarvestField.DEER_HUNTING_TYPE -> deerHuntingType(fieldSpecification, harvest)
            CommonHarvestField.DEER_HUNTING_OTHER_TYPE_DESCRIPTION -> deerHuntingOtherTypeDescription(fieldSpecification, harvest)
            CommonHarvestField.HEADLINE_SPECIMEN -> specimenDetails(fieldSpecification)
            CommonHarvestField.GENDER -> gender(fieldSpecification, harvest)
            CommonHarvestField.AGE -> age(fieldSpecification, harvest)
            CommonHarvestField.NOT_EDIBLE -> notEdible(fieldSpecification, harvest)
            CommonHarvestField.WEIGHT -> weight(fieldSpecification, harvest)
            CommonHarvestField.WEIGHT_ESTIMATED -> weightEstimated(fieldSpecification, harvest)
            CommonHarvestField.WEIGHT_MEASURED -> weightMeasured(fieldSpecification, harvest)
            CommonHarvestField.FITNESS_CLASS -> fitnessClass(fieldSpecification, harvest)
            CommonHarvestField.ANTLERS_TYPE -> antlersType(fieldSpecification, harvest)
            CommonHarvestField.ANTLERS_WIDTH -> antlersWidth(fieldSpecification, harvest)
            CommonHarvestField.ANTLER_POINTS_LEFT -> antlerPointsLeft(fieldSpecification, harvest)
            CommonHarvestField.ANTLER_POINTS_RIGHT -> antlerPointsRight(fieldSpecification, harvest)
            CommonHarvestField.ANTLERS_LOST -> antlersLost(fieldSpecification, harvest)
            CommonHarvestField.ANTLERS_GIRTH -> antlersGirth(fieldSpecification, harvest)
            CommonHarvestField.ANTLER_SHAFT_WIDTH -> antlerShaftWidth(fieldSpecification, harvest)
            CommonHarvestField.ANTLERS_LENGTH -> antlersLength(fieldSpecification, harvest)
            CommonHarvestField.ANTLERS_INNER_WIDTH -> antlersInnerWidth(fieldSpecification, harvest)
            CommonHarvestField.ALONE -> alone(fieldSpecification, harvest)
            CommonHarvestField.ADDITIONAL_INFORMATION -> additionalInformation(fieldSpecification, harvest)
            CommonHarvestField.ADDITIONAL_INFORMATION_INSTRUCTIONS -> additionalInformationInstructions(fieldSpecification, harvest)
            CommonHarvestField.ANTLER_INSTRUCTIONS -> antlerInstructions(fieldSpecification, harvest)
            CommonHarvestField.DESCRIPTION -> description(fieldSpecification, harvest)

            CommonHarvestField.GREY_SEAL_HUNTING_METHOD -> greySealHuntingMethod(fieldSpecification, harvest)
            CommonHarvestField.WILD_BOAR_FEEDING_PLACE -> wildBoarFeedingPlace(fieldSpecification, harvest)
            CommonHarvestField.IS_TAIGA_BEAN_GOOSE -> taigaBeanGoose(fieldSpecification, harvest)
            CommonHarvestField.SELECT_PERMIT -> selectPermit(fieldSpecification, harvest)
            CommonHarvestField.PERMIT_INFORMATION -> permitInformation(fieldSpecification, harvest)
            CommonHarvestField.PERMIT_REQUIRED_NOTIFICATION -> permitRequiredNotification(fieldSpecification)
            // explicitly list unexpected fields, don't use else here!
            CommonHarvestField.ACTOR,
            CommonHarvestField.ACTOR_HUNTER_NUMBER,
            CommonHarvestField.ACTOR_HUNTER_NUMBER_INFO_OR_ERROR,
            CommonHarvestField.AUTHOR,
            CommonHarvestField.HARVEST_REPORT_STATE -> {
                return null
                //throw RuntimeException("Was not expecting $fieldSpecification to be displayed")
            }
        }
    }

    private fun selectPermit(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData,
    ): BooleanField<CommonHarvestField> {
        return BooleanField(
            id = fieldSpecification.fieldId,
            value = when (harvest.permitNumber) {
                null -> false
                else -> true
            }
        ) {
            label = stringProvider.getString(RR.string.harvest_label_select_permit)
            readOnly = false
            appearance = BooleanField.Appearance.CHECKBOX
            paddingBottom = Padding.SMALL
        }
    }

    @Suppress("NAME_SHADOWING")
    private fun permitInformation(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData,
    ): LabelField<CommonHarvestField>? {
        return harvest.permitNumber
            ?.let { permitNumber ->
                val permitType = permitProvider?.getPermit(permitNumber)?.permitType
                    ?: harvest.permitType

                // prefix with permit type if exists, otherwise display just the number
                permitType?.let { permitType ->
                    "$permitType\n$permitNumber"
                } ?: permitNumber
            }
            ?.let { permitText ->
                LabelField(
                    id = fieldSpecification.fieldId,
                    text = permitText,
                    type = LabelField.Type.LINK
                ) {
                    allCaps = true
                    paddingTop = Padding.NONE
                }
            }
    }

    private fun permitRequiredNotification(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
    ): LabelField<CommonHarvestField> {
        return LabelField(
            id = fieldSpecification.fieldId,
            text = stringProvider.getString(RR.string.harvest_label_permit_required),
            type = LabelField.Type.ERROR
        ) {
            highlightBackground = true
            paddingTop = Padding.NONE
        }
    }

    private fun speciesCode(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData,
        showEntityImage: Boolean
    ): SpeciesField<CommonHarvestField> {
        return SpeciesField(
            id = fieldSpecification.fieldId,
            species = harvest.species,
            entityImage = harvest.images.primaryImage,
        ) {
            requirementStatus = fieldSpecification.requirementStatus
            this.showEntityImage = showEntityImage
            readOnly = !canChangeSpecies
            selectableSpecies = selectableHarvestSpecies
        }
    }

    private fun dateAndTime(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): DateAndTimeField<CommonHarvestField> {
        return DateAndTimeField(fieldSpecification.fieldId, harvest.pointOfTime) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            maxDateTime = currentDateTimeProvider?.now()
        }
    }

    private fun errorDateNotWithinPermit(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
    ): LabelField<CommonHarvestField> {
        return LabelField(
            id = fieldSpecification.fieldId,
            text = stringProvider.getString(RR.string.group_hunting_day_error_dates_not_within_permit),
            type = LabelField.Type.ERROR,
        ) {
            paddingTop = Padding.NONE
        }
    }

    private fun errorDatetimeInFuture(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
    ): LabelField<CommonHarvestField> {
        return LabelField(
            id = fieldSpecification.fieldId,
            text = stringProvider.getString(RR.string.error_datetime_in_future),
            type = LabelField.Type.ERROR,
        ) {
            paddingTop = Padding.NONE
        }
    }

    private fun huntingDayAndTime(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): HuntingDayAndTimeField<CommonHarvestField> {
        return HuntingDayAndTimeField(
            id = fieldSpecification.fieldId,
            huntingDayId = harvest.huntingDayId,
            dateAndTime = harvest.pointOfTime
        ) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_hunting_day_and_time)
            paddingBottom = Padding.MEDIUM_LARGE
        }
    }

    private fun errorTimeNotWithinHuntingDay(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
    ): LabelField<CommonHarvestField> {
        return LabelField(
            id = fieldSpecification.fieldId,
            text = stringProvider.getString(RR.string.group_hunting_error_time_not_within_hunting_day),
            type = LabelField.Type.ERROR,
        ) {
            paddingTop = Padding.NONE
        }
    }

    private fun deerHuntingType(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): StringListField<CommonHarvestField> {
        return deerHuntingTypeFieldFactory.create(
            fieldId = fieldSpecification.fieldId,
            currentEnumValue = harvest.deerHuntingType,
            allowEmptyValue = fieldSpecification.requirementStatus.isRequired().not()
        ) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_deer_hunting_type)
        }
    }

    private fun shooter(fieldSpecification: FieldSpecification<CommonHarvestField>): LabelField<CommonHarvestField> {
        return LabelField(
            id = fieldSpecification.fieldId,
            text = stringProvider.getString(RR.string.group_hunting_proposed_group_harvest_shooter),
            type = LabelField.Type.CAPTION
        ) {
            paddingBottom = Padding.SMALL // content right below this item
        }
    }

    private fun specimenDetails(fieldSpecification: FieldSpecification<CommonHarvestField>): LabelField<CommonHarvestField> {
        return LabelField(
            id = fieldSpecification.fieldId,
            text = stringProvider.getString(RR.string.group_hunting_proposed_group_harvest_specimen),
            type = LabelField.Type.CAPTION
        ) {
            paddingBottom = Padding.SMALL // content right below this item
        }
    }

    private fun deerHuntingOtherTypeDescription(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): StringField<CommonHarvestField> {
        return StringField(fieldSpecification.fieldId, harvest.deerHuntingOtherTypeDescription ?: "") {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_deer_hunting_other_type_description)
            paddingTop = Padding.NONE
        }
    }

    private fun location(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): LocationField<CommonHarvestField> {
        return LocationField(fieldSpecification.fieldId, harvest.location) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
        }
    }

    private fun specimenAmount(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): IntField<CommonHarvestField> {
        return IntField(fieldSpecification.fieldId, harvest.amount) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_amount)
            maxValue = HarvestConstants.MAX_SPECIMEN_AMOUNT
        }
    }

    private fun specimens(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData,
        harvestReportingType: HarvestReportingType,
    ): SpecimenField<CommonHarvestField> {
        return specimenFieldProducer.createSpecimenField(
            fieldSpecification = fieldSpecification,
            harvest = harvest,
            harvestReportingType = harvestReportingType,
        ) {
            readOnly = false
        }
    }

    private fun gender(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): GenderField<CommonHarvestField> {
        val gender = harvest.specimens.firstOrNull()?.gender?.value ?: Gender.UNKNOWN
        return GenderField(fieldSpecification.fieldId, gender) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            paddingTop = Padding.SMALL_MEDIUM
        }
    }

    private fun age(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): AgeField<CommonHarvestField> {
        val age = harvest.specimens.firstOrNull()?.age?.value ?: GameAge.UNKNOWN
        return AgeField(fieldSpecification.fieldId, age) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
        }
    }

    private fun notEdible(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): BooleanField<CommonHarvestField> {
        val notEdible = harvest.specimens.firstOrNull()?.notEdible
        return BooleanField(fieldSpecification.fieldId, notEdible) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_not_edible)
            appearance = BooleanField.Appearance.YES_NO_BUTTONS
        }
    }

    private fun weight(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ) = weightField(
        fieldSpecification = fieldSpecification,
        species = harvest.species,
        weightValue = harvest.specimens.firstOrNull()?.weight,
        label = RR.string.harvest_label_weight
    )

    private fun weightEstimated(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ) = weightField(
        fieldSpecification = fieldSpecification,
        species = harvest.species,
        weightValue = harvest.specimens.firstOrNull()?.weightEstimated,
        label = RR.string.harvest_label_weight_estimated
    )

    private fun weightMeasured(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ) = weightField(
        fieldSpecification = fieldSpecification,
        species = harvest.species,
        weightValue = harvest.specimens.firstOrNull()?.weightMeasured,
        label = RR.string.harvest_label_weight_measured
    )

    private fun weightField(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        species: Species,
        weightValue: Double?,
        label: RR.string,
    ): DoubleField<CommonHarvestField> {
        return DoubleField(fieldSpecification.fieldId, weightValue) {
            readOnly = false
            decimals = WeightFormatter.getDecimalCount(species)
            requirementStatus = fieldSpecification.requirementStatus
            maxValue = SpeciesConstants.MAX_WEIGHT
            this.label = stringProvider.getString(label)
        }
    }

    private fun greySealHuntingMethod(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): StringListField<CommonHarvestField> {
        return greySealHuntingMethodFactory.create(
            fieldId = fieldSpecification.fieldId,
            currentEnumValue = harvest.greySealHuntingMethod,
            allowEmptyValue = fieldSpecification.requirementStatus.isRequired().not()
        ) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_grey_seal_hunting_method)
        }
    }

    private fun wildBoarFeedingPlace(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): BooleanField<CommonHarvestField> {
        return BooleanField(fieldSpecification.fieldId, harvest.feedingPlace) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_wild_boar_feeding_place)
            appearance = BooleanField.Appearance.CHECKBOX
        }
    }

    private fun taigaBeanGoose(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): BooleanField<CommonHarvestField> {
        return BooleanField(fieldSpecification.fieldId, harvest.taigaBeanGoose) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_is_taiga_bean_goose)
            appearance = BooleanField.Appearance.CHECKBOX
        }
    }

    private fun fitnessClass(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): StringListField<CommonHarvestField> {
        val fitnessClass: BackendEnum<GameFitnessClass> =
            harvest.specimens.firstOrNull()?.fitnessClass ?: BackendEnum.create(null)
        return fitnessClassFieldFactory.create(
            fieldId = fieldSpecification.fieldId,
            currentEnumValue = fitnessClass,
            allowEmptyValue = fieldSpecification.requirementStatus.isRequired().not()
        ) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_fitness_class)
        }
    }

    private fun antlersType(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): StringListField<CommonHarvestField> {
        val antlersType: BackendEnum<GameAntlersType> =
            harvest.specimens.firstOrNull()?.antlersType ?: BackendEnum.create(null)
        return antlersTypeFieldFactory.create(
            fieldId = fieldSpecification.fieldId,
            currentEnumValue = antlersType,
            allowEmptyValue = fieldSpecification.requirementStatus.isRequired().not()
        ) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_antlers_type)
        }
    }

    private fun antlersWidth(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): IntField<CommonHarvestField> {
        val antlersWidth = harvest.specimens.firstOrNull()?.antlersWidth
        return IntField(fieldSpecification.fieldId, antlersWidth) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            maxValue = SpeciesConstants.MAX_ANTLERS_WIDTH
            label = stringProvider.getString(RR.string.harvest_label_antlers_width)
        }
    }

    private fun antlerPointsLeft(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): IntField<CommonHarvestField> {
        val antlerPointsLeft = harvest.specimens.firstOrNull()?.antlerPointsLeft
        return IntField(fieldSpecification.fieldId, antlerPointsLeft) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            maxValue = SpeciesConstants.MAX_ANTLER_POINTS
            label =
                stringProvider.getString(RR.string.harvest_label_antler_points_left)
        }
    }

    private fun antlerPointsRight(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): IntField<CommonHarvestField> {
        val antlerPointsRight = harvest.specimens.firstOrNull()?.antlerPointsRight
        return IntField(fieldSpecification.fieldId, antlerPointsRight) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            maxValue = SpeciesConstants.MAX_ANTLER_POINTS
            label =
                stringProvider.getString(RR.string.harvest_label_antler_points_right)
        }
    }

    private fun antlersLost(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): BooleanField<CommonHarvestField> {
        val antlersLost = harvest.specimens.firstOrNull()?.antlersLost
        return BooleanField(fieldSpecification.fieldId, antlersLost) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_antlers_lost)
            appearance = BooleanField.Appearance.YES_NO_BUTTONS
        }
    }

    private fun antlersGirth(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): IntField<CommonHarvestField> {
        val antlersGirth = harvest.specimens.firstOrNull()?.antlersGirth
        return IntField(fieldSpecification.fieldId, antlersGirth) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            maxValue = SpeciesConstants.MAX_ANTLERS_GIRTH
            label = stringProvider.getString(RR.string.harvest_label_antlers_girth)
        }
    }

    private fun antlerShaftWidth(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): IntField<CommonHarvestField> {
        val antlerShaftWidth = harvest.specimens.firstOrNull()?.antlerShaftWidth
        return IntField(fieldSpecification.fieldId, antlerShaftWidth) {
            readOnly = false
            maxValue = SpeciesConstants.MAX_ANTLER_SHAFT_WIDTH
            label =
                stringProvider.getString(RR.string.harvest_label_antler_shaft_width)
        }
    }

    private fun antlersLength(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): IntField<CommonHarvestField> {
        val antlersLength = harvest.specimens.firstOrNull()?.antlersLength
        return IntField(fieldSpecification.fieldId, antlersLength) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            maxValue = SpeciesConstants.MAX_ANTLERS_LENGTH
            label = stringProvider.getString(RR.string.harvest_label_antlers_length)
        }
    }

    private fun antlersInnerWidth(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): IntField<CommonHarvestField> {
        val antlersInnerWidth = harvest.specimens.firstOrNull()?.antlersInnerWidth
        return IntField(fieldSpecification.fieldId, antlersInnerWidth) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            maxValue = SpeciesConstants.MAX_ANTLERS_INNER_WIDTH
            label =
                stringProvider.getString(RR.string.harvest_label_antlers_inner_width)
        }
    }

    private fun alone(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): BooleanField<CommonHarvestField> {
        val alone = harvest.specimens.firstOrNull()?.alone
        return BooleanField(fieldSpecification.fieldId, alone) {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_alone)
            appearance = BooleanField.Appearance.YES_NO_BUTTONS
        }
    }

    private fun additionalInformation(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData
    ): StringField<CommonHarvestField> {
        val additionalInfo = harvest.specimens.firstOrNull()?.additionalInfo
        return StringField(fieldSpecification.fieldId, additionalInfo ?: "") {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label =
                stringProvider.getString(RR.string.harvest_label_additional_information)
        }
    }

    private fun additionalInformationInstructions(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData,
    ): LabelField<CommonHarvestField> {
        val instructions = when (harvest.species.knownSpeciesCodeOrNull()) {
            SpeciesCodes.MOOSE_ID,
            SpeciesCodes.FALLOW_DEER_ID,
            SpeciesCodes.WILD_FOREST_DEER_ID,
            SpeciesCodes.ROE_DEER_ID ->
                stringProvider.getString(RR.string.harvest_label_additional_information_instructions)
            SpeciesCodes.WHITE_TAILED_DEER_ID ->
                stringProvider.getString(RR.string.harvest_label_additional_information_instructions_white_tailed_deer)
            else -> error("Invalid species for additional information instructions")
        }
        return LabelField(
            id = fieldSpecification.fieldId,
            text = instructions,
            type = LabelField.Type.INFO,
        ) {
            paddingTop = Padding.NONE
        }
    }

    private fun antlerInstructions(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData,
    ): InstructionsField<CommonHarvestField> {
        val type = when (harvest.species.knownSpeciesCodeOrNull()) {
            SpeciesCodes.MOOSE_ID -> InstructionsField.Type.MOOSE_ANTLER_INSTRUCTIONS
            SpeciesCodes.WHITE_TAILED_DEER_ID -> InstructionsField.Type.WHITE_TAILED_DEER_ANTLER_INSTRUCTIONS
            SpeciesCodes.ROE_DEER_ID -> InstructionsField.Type.ROE_DEER_ANTLER_INSTRUCTIONS
            else -> error("Invalid species for antler instructions")
        }
        return InstructionsField(fieldSpecification.fieldId, type)
    }

    private fun description(
        fieldSpecification: FieldSpecification<CommonHarvestField>,
        harvest: CommonHarvestData,
    ): StringField<CommonHarvestField> {
        return StringField(fieldSpecification.fieldId, harvest.description ?: "") {
            readOnly = false
            requirementStatus = fieldSpecification.requirementStatus
            label = stringProvider.getString(RR.string.harvest_label_description)
        }
    }
}
