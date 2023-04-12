package fi.riista.common.domain.harvest.ui.view

import co.touchlab.stately.ensureNeverFrozen
import fi.riista.common.domain.content.SpeciesResolver
import fi.riista.common.domain.harvest.model.CommonHarvest
import fi.riista.common.domain.harvest.model.CommonHarvestData
import fi.riista.common.domain.harvest.model.toCommonHarvestData
import fi.riista.common.domain.harvest.ui.CommonHarvestField
import fi.riista.common.domain.harvest.ui.fields.CommonHarvestFields
import fi.riista.common.domain.permit.PermitProvider
import fi.riista.common.domain.season.HarvestSeasons
import fi.riista.common.logging.getLogger
import fi.riista.common.resources.StringProvider
import fi.riista.common.ui.controller.ControllerWithLoadableModel
import fi.riista.common.ui.controller.ViewModelLoadStatus
import fi.riista.common.ui.dataField.DataField
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow


/**
 * A controller for viewing [CommonHarvest] information
 */
class ViewHarvestController internal constructor(
    private val commonHarvestFields: CommonHarvestFields,
    permitProvider: PermitProvider,
    stringProvider: StringProvider,
) : ControllerWithLoadableModel<ViewHarvestViewModel>() {

    // main constructor to be used from outside
    constructor(
        harvestSeasons: HarvestSeasons,
        speciesResolver: SpeciesResolver,
        permitProvider: PermitProvider,
        stringProvider: StringProvider,
    ): this(
        commonHarvestFields = CommonHarvestFields(
            harvestSeasons = harvestSeasons,
            speciesResolver = speciesResolver,
        ),
        permitProvider = permitProvider,
        stringProvider = stringProvider,
    )

    private val dataFieldProducer = ViewHarvestFieldProducer(permitProvider, stringProvider)

    var harvest: CommonHarvest? = null

    init {
        // should be accessed from UI thread only
        ensureNeverFrozen()
    }

    override fun createLoadViewModelFlow(refresh: Boolean):
            Flow<ViewModelLoadStatus<ViewHarvestViewModel>> = flow {
        emit(ViewModelLoadStatus.Loading)

        val harvestData = harvest?.toCommonHarvestData()
        if (harvestData != null) {
            emit(ViewModelLoadStatus.Loaded(
                viewModel = createViewModel(
                    harvest = harvestData,
                )
            ))
        } else {
            logger.w { "Did you forget to set harvest before loading viewModel?" }
            emit(ViewModelLoadStatus.LoadFailed)
        }
    }

    private fun createViewModel(
        harvest: CommonHarvestData,
    ): ViewHarvestViewModel {
        return ViewHarvestViewModel(
            harvest = harvest,
            fields = produceDataFields(harvest),
            canEdit = harvest.canEdit,
        )
    }

    private fun produceDataFields(harvest: CommonHarvestData): List<DataField<CommonHarvestField>> {
        val fieldsToBeDisplayed = commonHarvestFields.getFieldsToBeDisplayed(
            harvest = harvest,
            mode = CommonHarvestFields.Context.Mode.VIEW,
        )

        return fieldsToBeDisplayed.mapNotNull { fieldSpecification ->
            dataFieldProducer.createField(
                fieldSpecification = fieldSpecification,
                harvest = harvest
            )
        }
    }

    companion object {
        private val logger by getLogger(ViewHarvestController::class)
    }
}

