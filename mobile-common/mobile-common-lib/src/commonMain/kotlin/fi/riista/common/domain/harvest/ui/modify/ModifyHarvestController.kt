package fi.riista.common.domain.harvest.ui.modify

import co.touchlab.stately.concurrency.AtomicReference
import co.touchlab.stately.ensureNeverFrozen
import fi.riista.common.domain.constants.SpeciesCode
import fi.riista.common.domain.content.SpeciesResolver
import fi.riista.common.domain.harvest.model.CommonHarvest
import fi.riista.common.domain.harvest.model.CommonHarvestData
import fi.riista.common.domain.harvest.model.toCommonHarvest
import fi.riista.common.domain.harvest.ui.CommonHarvestField
import fi.riista.common.domain.harvest.ui.common.HarvestSpecimenFieldProducer
import fi.riista.common.domain.harvest.ui.fields.CommonHarvestFields
import fi.riista.common.domain.harvest.validation.CommonHarvestValidator
import fi.riista.common.domain.model.CommonLocation
import fi.riista.common.domain.model.CommonSpecimenData
import fi.riista.common.domain.model.Species
import fi.riista.common.domain.model.asKnownLocation
import fi.riista.common.domain.permit.PermitProvider
import fi.riista.common.domain.permit.model.CommonPermit
import fi.riista.common.domain.season.HarvestSeasons
import fi.riista.common.domain.specimens.ui.SpecimenFieldType
import fi.riista.common.logging.getLogger
import fi.riista.common.model.BackendEnum
import fi.riista.common.resources.StringProvider
import fi.riista.common.ui.controller.ControllerWithLoadableModel
import fi.riista.common.ui.controller.HasUnreproducibleState
import fi.riista.common.ui.controller.ViewModelLoadStatus
import fi.riista.common.ui.dataField.FieldSpecification
import fi.riista.common.ui.dataField.noRequirement
import fi.riista.common.ui.intent.IntentHandler
import fi.riista.common.util.LocalDateTimeProvider
import fi.riista.common.util.withNumberOfElements
import kotlinx.serialization.Serializable

/**
 * A controller for modifying [CommonHarvestData] information
 */
abstract class ModifyHarvestController internal constructor(
    harvestSeasons: HarvestSeasons,
    protected val currentTimeProvider: LocalDateTimeProvider,
    internal val permitProvider: PermitProvider,
    speciesResolver: SpeciesResolver,
    stringProvider: StringProvider,
) : ControllerWithLoadableModel<ModifyHarvestViewModel>(),
    IntentHandler<ModifyHarvestIntent>,
    HasUnreproducibleState<ModifyHarvestController.SavedState> {

    private val harvestFields = CommonHarvestFields(
        harvestSeasons, speciesResolver
    )

    val eventDispatchers: ModifyHarvestEventDispatcher by lazy {
        ModifyHarvestEventToIntentMapper(intentHandler = this)
    }

    internal var restoredHarvestData: CommonHarvestData? = null

    private val _modifyHarvestActionHandler = AtomicReference<ModifyHarvestActionHandler?>(null)
    var modifyHarvestActionHandler: ModifyHarvestActionHandler?
        get() = _modifyHarvestActionHandler.get()
        set(value) {
            _modifyHarvestActionHandler.set(value)
        }

    /**
     * Can the harvest location be moved automatically?
     *
     * Automatic location updates should be prevented if user has manually specified
     * the location for the harvest event.
     */
    protected var harvestLocationCanBeUpdatedAutomatically: Boolean = true

    private val pendingIntents = mutableListOf<ModifyHarvestIntent>()

    private val fieldProducer = ModifyHarvestFieldProducer(
        canChangeSpecies = true,
        permitProvider = permitProvider,
        stringProvider = stringProvider,
        currentDateTimeProvider = currentTimeProvider,
    )

    init {
        // should be accessed from UI thread only
        ensureNeverFrozen()
    }

    fun getValidatedHarvest(): CommonHarvest? {
        return getLoadedViewModelOrNull()
            ?.getValidatedHarvestOrNull()
            ?.toCommonHarvest()
    }

    override fun handleIntent(intent: ModifyHarvestIntent) {
        // It is possible that intent is sent already before we have Loaded viewmodel.
        // This is the case e.g. when location is updated in external activity (on android)
        // and the activity/fragment utilizing this controller was destroyed. In that case
        // the call cycle could be:
        // - finish map activity with result
        // - create fragment / activity (that will utilize this controller)
        // - restore controller state
        // - handle activity result (e.g. dispatch location updated event)
        // - resume -> loadViewModel
        //
        // tackle the above situation by collecting intents to pendingIntents and restored
        // viewmodel with those when viewModel has been loaded
        val viewModel = getLoadedViewModelOrNull()
        if (viewModel != null) {
            updateViewModel(ViewModelLoadStatus.Loaded(
                viewModel = handleIntent(intent, viewModel)
            ))
        } else {
            pendingIntents.add(intent)
        }
    }

    private fun handleIntent(
        intent: ModifyHarvestIntent,
        viewModel: ModifyHarvestViewModel,
    ): ModifyHarvestViewModel {
        val harvest = viewModel.harvest

        // the current permit. Should be updated if permit is changed.
        var currentPermit = viewModel.permit

        val updatedHarvest = when (intent) {
            is ModifyHarvestIntent.LaunchPermitSelection -> {
                requestModifyHarvestAction(
                    action = ModifyHarvestAction.SelectPermit(
                        currentPermitNumber = harvest.permitNumber.takeIf { intent.restrictToCurrentPermitNumber }
                    )
                )
                return viewModel
            }
            is ModifyHarvestIntent.ClearSelectedPermit -> {
                // clear the permit so that it won't be used in validation
                currentPermit = null

                harvest.copy(
                    permitNumber = null,
                    permitType = null,
                )
            }
            is ModifyHarvestIntent.SelectPermit -> {
                val newSpecies: Species = intent.speciesCode
                    ?.let { speciesCode ->
                        Species.Known(speciesCode)
                            .takeIf { intent.permit.isAvailableForSpecies(it) }
                    }
                    ?: harvest.species.takeIf { intent.permit.isAvailableForSpecies(it) }
                    ?: Species.Unknown

                currentPermit = intent.permit

                harvest.copy(
                    species = newSpecies,
                    permitNumber = intent.permit.permitNumber,
                    permitType = intent.permit.permitType
                )
            }
            is ModifyHarvestIntent.ChangeSpecies -> {
                if (fieldProducer.selectableHarvestSpecies.contains(candidate = intent.species)) {
                    val harvestWithChangedSpecies = if (currentPermit?.isAvailableForSpecies(intent.species) == true) {
                        harvest.copy(
                            species = intent.species,
                            // don't clear permit information
                        )
                    } else {
                        // clear the permit so that it won't be used in validation
                        currentPermit = null

                        harvest.copy(
                            species = intent.species,
                            permitNumber = null,
                            permitType = null,
                            harvestReportRequired = false,
                            harvestReportState = BackendEnum.create(null),
                            stateAcceptedToHarvestPermit = BackendEnum.create(null),
                        )
                    }

                    // possible specimens fields depend on selected species
                    harvestWithChangedSpecies.withInvalidatedSpecimens()
                } else {
                    harvest
                }
            }
            is ModifyHarvestIntent.SetEntityImage -> {
                harvest.copy(
                    images = harvest.images.withNewPrimaryImage(intent.image)
                )
            }
            is ModifyHarvestIntent.ChangeSpecimenAmount -> {
                if (intent.specimenAmount == null) {
                    harvest.copy(
                        amount = intent.specimenAmount
                    )
                } else {
                    val updatedSpecimens = harvest.specimens.withNumberOfElements(intent.specimenAmount) {
                        CommonSpecimenData().ensureDefaultValuesAreSet()
                    }
                    harvest.updateSpecimens(
                        specimens = updatedSpecimens
                    )
                }
            }
            is ModifyHarvestIntent.ChangeSpecimenData ->
                harvest.updateSpecimens(
                    specimens = intent.specimenData.specimens,
                )
            is ModifyHarvestIntent.ChangeDescription ->
                harvest.copy(description = intent.description)
            is ModifyHarvestIntent.ChangeAdditionalInformation -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    additionalInfo = intent.newAdditionalInformation
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeGender -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    gender = BackendEnum.create(intent.newGender)
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeDateAndTime -> {
                harvest.copy(pointOfTime = intent.newDateAndTime.coerceAtMost(currentTimeProvider.now()))
            }
            is ModifyHarvestIntent.ChangeDeerHuntingType -> {
                harvest.copy(deerHuntingType = intent.deerHuntingType)
            }
            is ModifyHarvestIntent.ChangeDeerHuntingOtherTypeDescription -> {
                harvest.copy(deerHuntingOtherTypeDescription = intent.deerHuntingOtherTypeDescription)
            }
            is ModifyHarvestIntent.ChangeAge -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    age = BackendEnum.create(intent.newAge)
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeLocation -> {
                if (intent.locationChangedAfterUserInteraction) {
                    harvestLocationCanBeUpdatedAutomatically = false
                }

                harvest.copy(location = intent.newLocation.asKnownLocation())
            }
            is ModifyHarvestIntent.ChangeNotEdible -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    notEdible = intent.newNotEdible
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeWeight -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    weight = intent.newWeight
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeWeightEstimated -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    weightEstimated = intent.newWeight
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeWeightMeasured -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    weightMeasured = intent.newWeight
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeFitnessClass -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    fitnessClass = intent.newFitnessClass
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeAntlersType -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    antlersType = intent.newAntlersType
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeAntlersWidth -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    antlersWidth = intent.newAntlersWidth
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeAntlerPointsLeft -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    antlerPointsLeft = intent.newAntlerPointsLeft
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeAntlerPointsRight -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    antlerPointsRight = intent.newAntlerPointsRight
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeAntlersLost -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    antlersLost = intent.newAntlersLost
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeAntlersGirth -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    antlersGirth = intent.newAntlersGirth
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeAntlerShaftWidth -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    antlerShaftWidth = intent.newAntlerShaftWidth
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeAntlersLength -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    antlersLength = intent.newAntlersLength
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeAntlersInnerWidth -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(
                    antlersInnerWidth = intent.newAntlersInnerWidth
                )
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeAlone -> {
                val specimen = getFirstSpecimenOrCreate(harvest).copy(alone = intent.newAlone)
                updateFirstSpecimen(harvest, specimen)
            }
            is ModifyHarvestIntent.ChangeWildBoarFeedingPlace ->
                harvest.copy(feedingPlace = intent.feedingPlace)
            is ModifyHarvestIntent.ChangeIsTaigaBean ->
                harvest.copy(taigaBeanGoose = intent.isTaigaBeanGoose)
            is ModifyHarvestIntent.ChangeGreySealHuntingMethod ->
                harvest.copy(greySealHuntingMethod = intent.greySealHuntingMethod)
            is ModifyHarvestIntent.ChangeTime,
            is ModifyHarvestIntent.ChangeHuntingDay,
            is ModifyHarvestIntent.ChangeActor,
            is ModifyHarvestIntent.ChangeActorHunterNumber -> harvest
        }

        return createViewModel(
            harvest = updatedHarvest,
            permit = currentPermit,
        )
    }

    private fun requestModifyHarvestAction(action: ModifyHarvestAction) {
        val handler = modifyHarvestActionHandler ?: kotlin.run {
            logger.w { "No action handler for modify harvest actions!" }
            return
        }

        handler.handleModifyHarvestAction(action)
    }

    private fun CommonHarvestData.withInvalidatedSpecimens(): CommonHarvestData {
        return updateSpecimens(
            specimens = List(size = amount ?: 1) {
                CommonSpecimenData().ensureDefaultValuesAreSet()
            },
        )
    }

    private fun CommonHarvestData.updateSpecimens(
        specimens: List<CommonSpecimenData>,
    ): CommonHarvestData {
        return copy(
            amount = specimens.size,
            specimens = specimens,
        )
    }

    private fun getFirstSpecimenOrCreate(harvest: CommonHarvestData) : CommonSpecimenData {
        return harvest.specimens.firstOrNull()
            ?: CommonSpecimenData().ensureDefaultValuesAreSet()
    }

    private fun updateFirstSpecimen(harvest: CommonHarvestData, specimen: CommonSpecimenData): CommonHarvestData {
        return harvest.copy(
            specimens = listOf(specimen) + harvest.specimens.drop(1)
        )
    }

    internal fun CommonSpecimenData.ensureDefaultValuesAreSet(): CommonSpecimenData {
        return copy(
            notEdible = notEdible ?: false,
            alone = alone ?: false,
            antlersLost = antlersLost ?: false
        )
    }

    override fun getUnreproducibleState(): SavedState? {
        return getLoadedViewModelOrNull()?.harvest?.let {
            SavedState(
                harvest = it,
                harvestLocationCanBeUpdatedAutomatically = harvestLocationCanBeUpdatedAutomatically
            )
        }
    }

    override fun restoreUnreproducibleState(state: SavedState) {
        restoredHarvestData = state.harvest
        harvestLocationCanBeUpdatedAutomatically = state.harvestLocationCanBeUpdatedAutomatically
    }

    internal fun createViewModel(
        harvest: CommonHarvestData,
        permit: CommonPermit?,
    ): ModifyHarvestViewModel {
        val harvestContext = harvestFields.createContext(
            harvest = harvest,
            mode = CommonHarvestFields.Context.Mode.EDIT,
        )
        var fieldsToBeDisplayed = harvestFields.getFieldsToBeDisplayed(harvestContext)

        val validationErrors = CommonHarvestValidator.validate(
            harvest = harvest,
            permit = permit,
            localDateTimeProvider = currentTimeProvider,
            displayedFields = fieldsToBeDisplayed,
        )

        val harvestIsValid = validationErrors.isEmpty()

        fieldsToBeDisplayed = fieldsToBeDisplayed.injectErrorLabels(validationErrors)

        return ModifyHarvestViewModel(
            harvest = harvest,
            permit = permit,
            fields = fieldsToBeDisplayed.mapNotNull { fieldSpecification ->
                fieldProducer.createField(
                    fieldSpecification = fieldSpecification,
                    harvest = harvest,
                    harvestReportingType = harvestContext.harvestReportingType,
                )
            },
            harvestIsValid = harvestIsValid
        )
    }

    protected fun ModifyHarvestViewModel.applyPendingIntents(): ModifyHarvestViewModel {
        var viewModel = this
        pendingIntents.forEach { intent ->
            viewModel = handleIntent(intent, viewModel)
        }
        pendingIntents.clear()

        return viewModel
    }

    private fun ModifyHarvestViewModel.getValidatedHarvestOrNull(): CommonHarvestData? {
        val displayedFields = harvestFields.getFieldsToBeDisplayed(
            harvest = harvest,
            mode = CommonHarvestFields.Context.Mode.EDIT
        )

        val validationErrors = CommonHarvestValidator.validate(
            harvest = harvest,
            permit = permit,
            localDateTimeProvider = currentTimeProvider,
            displayedFields = displayedFields,
        )
        if (validationErrors.isNotEmpty()) {
            return null
        }

        return harvest.createCopyWithFields(displayedFields)

    }

    private fun CommonHarvestData.createCopyWithFields(
        fields: List<FieldSpecification<CommonHarvestField>>,
    ): CommonHarvestData? {
        val fieldTypes: Set<CommonHarvestField> = fields.map { it.fieldId }.toSet()

        val harvestCopy = copy(
            location = location.takeIf {
                fieldTypes.contains(CommonHarvestField.LOCATION)
            } ?: CommonLocation.Unknown,
            species = species.takeIf {
                fieldTypes.contains(CommonHarvestField.SPECIES_CODE_AND_IMAGE) ||
                        fieldTypes.contains(CommonHarvestField.SPECIES_CODE)
            } ?: Species.Unknown,
            pointOfTime = pointOfTime.also {
                if (!fieldTypes.contains(CommonHarvestField.DATE_AND_TIME)) {
                    logger.e { "Fields didn't contain DATE_AND_TIME!" }
                    return null
                }
            },
            amount = amount.takeIf {
                fieldTypes.contains(CommonHarvestField.SPECIMEN_AMOUNT)
            },
            specimens = specimens.map { specimen ->
                specimen.createCopyWithFields(
                    speciesCode = species.knownSpeciesCodeOrNull(),
                    fieldTypes = fieldTypes
                )
            },
            deerHuntingType = deerHuntingType.takeIf {
                fieldTypes.contains(CommonHarvestField.DEER_HUNTING_TYPE)
            } ?: BackendEnum.create(null),
            deerHuntingOtherTypeDescription = deerHuntingOtherTypeDescription.takeIf {
                fieldTypes.contains(CommonHarvestField.DEER_HUNTING_OTHER_TYPE_DESCRIPTION)
            },
            permitNumber = permitNumber.takeIf {
                fieldTypes.contains(CommonHarvestField.PERMIT_INFORMATION)
            },
            permitType = permitType.takeIf {
                fieldTypes.contains(CommonHarvestField.PERMIT_INFORMATION)
            },
            feedingPlace = feedingPlace.takeIf {
                fieldTypes.contains(CommonHarvestField.WILD_BOAR_FEEDING_PLACE)
            },
            taigaBeanGoose = taigaBeanGoose.takeIf {
                fieldTypes.contains(CommonHarvestField.IS_TAIGA_BEAN_GOOSE)
            },
            greySealHuntingMethod = greySealHuntingMethod.takeIf {
                fieldTypes.contains(CommonHarvestField.GREY_SEAL_HUNTING_METHOD)
            } ?: BackendEnum.create(null),
            description = description.takeIf {
                fieldTypes.contains(CommonHarvestField.DESCRIPTION)
            },
        )

        return harvestCopy
    }

    private fun CommonSpecimenData.createCopyWithFields(
        speciesCode: SpeciesCode?,
        fieldTypes: Set<CommonHarvestField>,
    ): CommonSpecimenData {
        // two possibilities here. Either specimen is modified directly in harvest view or it is modified in
        // external view (EditSpecimensController). In the latter case the specimen fields are NOT determined
        // by the fieldTypes but HarvestSpecimenFieldProducer.
        //
        // Check the latter case first
        if (fieldTypes.contains(CommonHarvestField.SPECIMENS)) {
            val specimenFieldTypes = HarvestSpecimenFieldProducer.getSpecimenFieldTypes(speciesCode = speciesCode)

            // don't copy in order to make sure extra data is not included
            return CommonSpecimenData(
                remoteId = remoteId,
                revision = revision,
                gender = gender.takeIf { specimenFieldTypes.contains(SpecimenFieldType.GENDER) },
                age = age.takeIf { specimenFieldTypes.contains(SpecimenFieldType.AGE) },
                stateOfHealth = stateOfHealth.takeIf { specimenFieldTypes.contains(SpecimenFieldType.STATE_OF_HEALTH) },
                marking = marking.takeIf { specimenFieldTypes.contains(SpecimenFieldType.MARKING) },
                lengthOfPaw = lengthOfPaw.takeIf { specimenFieldTypes.contains(SpecimenFieldType.LENGTH_OF_PAW) },
                widthOfPaw = widthOfPaw.takeIf { specimenFieldTypes.contains(SpecimenFieldType.WIDTH_OF_PAW) },
                weight = weight.takeIf { specimenFieldTypes.contains(SpecimenFieldType.WEIGHT) },
                weightEstimated = null,
                weightMeasured = null,
                fitnessClass = null,
                antlersLost = null,
                antlersType = null,
                antlersWidth = null,
                antlerPointsLeft = null,
                antlerPointsRight = null,
                antlersGirth = null,
                antlersLength = null,
                antlersInnerWidth = null,
                antlerShaftWidth = null,
                notEdible = null,
                alone = null,
                additionalInfo = null,
            )
        }

        // don't copy in order to make sure extra data is not included
        return CommonSpecimenData(
            remoteId = remoteId,
            revision = revision,
            gender = gender.takeIf { fieldTypes.contains(CommonHarvestField.GENDER) },
            age = age.takeIf { fieldTypes.contains(CommonHarvestField.AGE) },
            stateOfHealth = null, // observation related field
            marking = null, // observation related field
            lengthOfPaw = null, // observation related field
            widthOfPaw = null, // observation related field
            weight = weight.takeIf { fieldTypes.contains(CommonHarvestField.WEIGHT) },
            weightEstimated = weightEstimated.takeIf { fieldTypes.contains(CommonHarvestField.WEIGHT_ESTIMATED) },
            weightMeasured = weightMeasured.takeIf { fieldTypes.contains(CommonHarvestField.WEIGHT_MEASURED) },
            fitnessClass = fitnessClass.takeIf { fieldTypes.contains(CommonHarvestField.FITNESS_CLASS) },
            antlersLost = antlersLost.takeIf { fieldTypes.contains(CommonHarvestField.ANTLERS_LOST) },
            antlersType = antlersType.takeIf { fieldTypes.contains(CommonHarvestField.ANTLERS_TYPE) },
            antlersWidth = antlersWidth.takeIf { fieldTypes.contains(CommonHarvestField.ANTLERS_WIDTH) },
            antlerPointsLeft = antlerPointsLeft.takeIf { fieldTypes.contains(CommonHarvestField.ANTLER_POINTS_LEFT) },
            antlerPointsRight = antlerPointsRight.takeIf { fieldTypes.contains(CommonHarvestField.ANTLER_POINTS_RIGHT) },
            antlersGirth = antlersGirth.takeIf { fieldTypes.contains(CommonHarvestField.ANTLERS_GIRTH) },
            antlersLength = antlersLength.takeIf { fieldTypes.contains(CommonHarvestField.ANTLERS_LENGTH) },
            antlersInnerWidth = antlersInnerWidth.takeIf { fieldTypes.contains(CommonHarvestField.ANTLERS_INNER_WIDTH) },
            antlerShaftWidth = antlerShaftWidth.takeIf { fieldTypes.contains(CommonHarvestField.ANTLER_SHAFT_WIDTH) },
            notEdible = notEdible.takeIf { fieldTypes.contains(CommonHarvestField.NOT_EDIBLE) },
            alone = alone.takeIf { fieldTypes.contains(CommonHarvestField.ALONE) },
            additionalInfo = additionalInfo.takeIf { fieldTypes.contains(CommonHarvestField.ADDITIONAL_INFORMATION) },
        )
    }

    private fun List<FieldSpecification<CommonHarvestField>>.injectErrorLabels(
        validationErrors: List<CommonHarvestValidator.Error>
    ): List<FieldSpecification<CommonHarvestField>> {
        if (validationErrors.isEmpty()) {
            return this
        }

        val result = mutableListOf<FieldSpecification<CommonHarvestField>>()

        forEach { fieldSpecification ->
            when (fieldSpecification.fieldId) {
                CommonHarvestField.DATE_AND_TIME -> {
                    result.add(fieldSpecification)

                    if (validationErrors.contains(CommonHarvestValidator.Error.DATE_NOT_WITHIN_PERMIT)) {
                        result.add(CommonHarvestField.ERROR_DATE_NOT_WITHIN_PERMIT.noRequirement())
                    }
                }
                CommonHarvestField.HUNTING_DAY_AND_TIME,
                CommonHarvestField.SPECIES_CODE,
                CommonHarvestField.ERROR_DATE_NOT_WITHIN_PERMIT,
                CommonHarvestField.ERROR_TIME_NOT_WITHIN_HUNTING_DAY,
                CommonHarvestField.LOCATION,
                CommonHarvestField.DEER_HUNTING_TYPE,
                CommonHarvestField.DEER_HUNTING_OTHER_TYPE_DESCRIPTION,
                CommonHarvestField.ACTOR_HUNTER_NUMBER,
                CommonHarvestField.ACTOR_HUNTER_NUMBER_INFO_OR_ERROR,
                CommonHarvestField.GENDER,
                CommonHarvestField.AGE,
                CommonHarvestField.NOT_EDIBLE,
                CommonHarvestField.ADDITIONAL_INFORMATION,
                CommonHarvestField.ADDITIONAL_INFORMATION_INSTRUCTIONS,
                CommonHarvestField.HEADLINE_SHOOTER,
                CommonHarvestField.HEADLINE_SPECIMEN,
                CommonHarvestField.WEIGHT,
                CommonHarvestField.WEIGHT_ESTIMATED,
                CommonHarvestField.WEIGHT_MEASURED,
                CommonHarvestField.FITNESS_CLASS,
                CommonHarvestField.ANTLER_INSTRUCTIONS,
                CommonHarvestField.ANTLERS_TYPE,
                CommonHarvestField.ANTLERS_WIDTH,
                CommonHarvestField.ANTLER_POINTS_LEFT,
                CommonHarvestField.ANTLER_POINTS_RIGHT,
                CommonHarvestField.ANTLERS_LOST,
                CommonHarvestField.ANTLERS_GIRTH,
                CommonHarvestField.ANTLER_SHAFT_WIDTH,
                CommonHarvestField.ANTLERS_LENGTH,
                CommonHarvestField.ANTLERS_INNER_WIDTH,
                CommonHarvestField.ACTOR,
                CommonHarvestField.AUTHOR,
                CommonHarvestField.ALONE,
                CommonHarvestField.SELECT_PERMIT,
                CommonHarvestField.PERMIT_INFORMATION,
                CommonHarvestField.PERMIT_REQUIRED_NOTIFICATION,
                CommonHarvestField.SPECIES_CODE_AND_IMAGE,
                CommonHarvestField.HARVEST_REPORT_STATE,
                CommonHarvestField.SPECIMEN_AMOUNT,
                CommonHarvestField.SPECIMENS,
                CommonHarvestField.WILD_BOAR_FEEDING_PLACE,
                CommonHarvestField.GREY_SEAL_HUNTING_METHOD,
                CommonHarvestField.IS_TAIGA_BEAN_GOOSE,
                CommonHarvestField.DESCRIPTION -> {
                    result.add(fieldSpecification)
                }

            }
        }
        return result
    }

    @Serializable
    data class SavedState internal constructor(
        internal val harvest: CommonHarvestData,
        internal val harvestLocationCanBeUpdatedAutomatically: Boolean,
    )

    companion object {
        private val logger by getLogger(ModifyHarvestController::class)
    }
}

