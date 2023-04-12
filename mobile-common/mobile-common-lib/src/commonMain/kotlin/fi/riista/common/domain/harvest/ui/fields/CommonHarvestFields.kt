package fi.riista.common.domain.harvest.ui.fields

import fi.riista.common.domain.constants.SpeciesCodes
import fi.riista.common.domain.content.SpeciesResolver
import fi.riista.common.domain.harvest.common.HarvestReportingTypeResolver
import fi.riista.common.domain.harvest.model.CommonHarvestData
import fi.riista.common.domain.harvest.model.HarvestReportingType
import fi.riista.common.domain.harvest.ui.CommonHarvestField
import fi.riista.common.domain.model.GameAge
import fi.riista.common.domain.model.Gender
import fi.riista.common.domain.model.getHuntingYear
import fi.riista.common.domain.season.HarvestSeasons
import fi.riista.common.ui.dataField.FieldRequirement
import fi.riista.common.ui.dataField.FieldSpecification
import fi.riista.common.ui.dataField.noRequirement
import fi.riista.common.ui.dataField.required
import fi.riista.common.ui.dataField.requiredIf
import fi.riista.common.ui.dataField.voluntary

internal class CommonHarvestFields internal constructor(
    private val harvestSeasons: HarvestSeasons,
    private val harvestFieldsPre2020: SpeciesSpecificHarvestFields,
    private val harvestFieldsAfter2020: SpeciesSpecificHarvestFields
) {
    private val harvestReportingTypeResolver = HarvestReportingTypeResolver(harvestSeasons)

    // main constructor to be used from outside
    constructor(
        harvestSeasons: HarvestSeasons,
        speciesResolver: SpeciesResolver,
    ): this(
        harvestSeasons = harvestSeasons,
        harvestFieldsPre2020 = SpeciesSpecificHarvestFieldsPre2020(speciesResolver),
        harvestFieldsAfter2020 = SpeciesSpecificHarvestFieldsAfter2020()
    )

    /**
     * The context based on which the specifications for [CommonHarvestData] fields are determined.
     */
    data class Context internal constructor(
        internal val harvest: CommonHarvestData,
        val harvestReportingType: HarvestReportingType,
        val mode: Mode
    ) {
        enum class Mode {
            VIEW,
            EDIT,
        }

        val speciesCode = harvest.species.knownSpeciesCodeOrNull()

        val adultMale: Boolean by lazy {
            harvest.specimens.getOrNull(0)
                ?.let {
                    it.age?.value == GameAge.ADULT && it.gender?.value == Gender.MALE
                } ?:false
        }

        val young: Boolean by lazy {
            harvest.specimens.getOrNull(0)
                ?.let {
                    it.age?.value == GameAge.YOUNG
                }
                    ?:false
        }

        val antlersLost: Boolean? by lazy {
            harvest.specimens.getOrNull(0)?.antlersLost
        }
    }

    fun getFieldsToBeDisplayed(
        harvest: CommonHarvestData,
        mode: Context.Mode
    ): List<FieldSpecification<CommonHarvestField>> {
        val harvestReportingType = harvestReportingTypeResolver.resolveHarvestReportingType(harvest)

        return getFieldsToBeDisplayed(Context(
            harvest = harvest,
            harvestReportingType = harvestReportingType,
            mode = mode,
        ))
    }

    fun getFieldsToBeDisplayed(context: Context): List<FieldSpecification<CommonHarvestField>> {
        val huntingYear = context.harvest.pointOfTime.date.getHuntingYear()
        val speciesSpecificFields =
            useFieldsIf(huntingYear >= 2020) { harvestFieldsAfter2020.getSpeciesSpecificFields(context) }
                    ?: harvestFieldsPre2020.getSpeciesSpecificFields(context)
                    ?: emptyList()

        val permitNumberRequired = when {
            context.harvestReportingType == HarvestReportingType.PERMIT -> true
            SPECIES_REQUIRING_PERMIT_WITHOUT_SEASON.contains(context.speciesCode) ->
                context.harvestReportingType != HarvestReportingType.SEASON
            else -> false
        }

        val editPermitFields: Array<FieldSpecification<CommonHarvestField>> =
            if (context.mode == Context.Mode.VIEW) {
                emptyArray()
            } else {
                listOfNotNull(
                    CommonHarvestField.SELECT_PERMIT.requiredIf(permitNumberRequired),
                    CommonHarvestField.PERMIT_INFORMATION.requiredIf(permitNumberRequired),
                    CommonHarvestField.PERMIT_REQUIRED_NOTIFICATION
                        .noRequirement()
                        .takeIf { permitNumberRequired && context.harvest.permitNumber == null }
                ).toTypedArray()
            }

        return listOfNotNull(
            CommonHarvestField.LOCATION.required(),
            // display after location only when editing
            *editPermitFields,

            CommonHarvestField.SPECIES_CODE_AND_IMAGE.required(),
            CommonHarvestField.DATE_AND_TIME.required(),
            CommonHarvestField.HARVEST_REPORT_STATE.noRequirement().takeIf {
                context.mode == Context.Mode.VIEW && context.harvest.harvestState != null
            },
            CommonHarvestField.PERMIT_INFORMATION.noRequirement().takeIf {
                // display after date and time only when viewing
                context.mode == Context.Mode.VIEW && permitNumberRequired
            },
        ) + speciesSpecificFields + listOf(
            CommonHarvestField.DESCRIPTION.voluntary()
        )
    }

    internal fun createContext(
        harvest: CommonHarvestData,
        mode: Context.Mode
    ): Context {
        return Context(
            harvest = harvest,
            harvestReportingType = harvestReportingTypeResolver.resolveHarvestReportingType(harvest),
            mode = mode
        )
    }

    private fun useFieldsIf(
        condition: Boolean,
        fieldsBlock: () -> List<FieldSpecification<CommonHarvestField>>?
    ): List<FieldSpecification<CommonHarvestField>>? {
        return if (condition) {
            fieldsBlock()
        } else {
            null
        }
    }


    companion object {
        internal val SPECIES_REQUIRING_PERMIT_WITHOUT_SEASON = setOf(
            SpeciesCodes.BEAN_GOOSE_ID,
            SpeciesCodes.BEAR_ID,
            SpeciesCodes.COMMON_EIDER_ID,
            SpeciesCodes.COOT_ID,
            SpeciesCodes.EUROPEAN_BEAVER_ID,
            SpeciesCodes.GARGANEY_ID,
            SpeciesCodes.GOOSANDER_ID,
            SpeciesCodes.GREYLAG_GOOSE_ID,
            SpeciesCodes.GREY_SEAL_ID,
            SpeciesCodes.LONG_TAILED_DUCK_ID,
            SpeciesCodes.LYNX_ID,
            SpeciesCodes.OTTER_ID,
            SpeciesCodes.PINTAIL_ID,
            SpeciesCodes.POCHARD_ID,
            SpeciesCodes.POLECAT_ID,
            SpeciesCodes.RED_BREASTED_MERGANSER_ID,
            SpeciesCodes.RINGED_SEAL_ID,
            SpeciesCodes.ROE_DEER_ID,
            SpeciesCodes.SHOVELER_ID,
            SpeciesCodes.TUFTED_DUCK_ID,
            SpeciesCodes.WIGEON_ID,
            SpeciesCodes.WILD_BOAR_ID,
            SpeciesCodes.WOLF_ID,
            SpeciesCodes.WOLVERINE_ID,
        )
    }
}

/**
 * Resolves the field requirement.
 *
 * Returns the field as required or with given fallback requirement type.
 */
internal fun CommonHarvestField.resolveRequirement(
    context: CommonHarvestFields.Context,
    fallbackRequirement: FieldRequirement.Type = FieldRequirement.Type.VOLUNTARY,
    indicateRequirementStatus: Boolean = true,
): FieldSpecification<CommonHarvestField> {
    val speciesCode = context.speciesCode ?: kotlin.run {
        return FieldSpecification(
            fieldId = this,
            requirementStatus = FieldRequirement(fallbackRequirement, indicateRequirementStatus)
        )
    }

    return resolveRequirement(
        speciesCode = speciesCode,
        harvestReportingType = context.harvestReportingType,
        fallbackRequirement = fallbackRequirement,
        indicateRequirementStatus = indicateRequirementStatus,
    )
}
