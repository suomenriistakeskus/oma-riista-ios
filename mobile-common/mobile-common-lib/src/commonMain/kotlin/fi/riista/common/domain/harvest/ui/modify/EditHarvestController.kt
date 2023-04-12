package fi.riista.common.domain.harvest.ui.modify

import fi.riista.common.domain.constants.Constants
import fi.riista.common.domain.content.SpeciesResolver
import fi.riista.common.domain.harvest.model.CommonHarvest
import fi.riista.common.domain.permit.PermitProvider
import fi.riista.common.domain.permit.getPermit
import fi.riista.common.domain.season.HarvestSeasons
import fi.riista.common.resources.StringProvider
import fi.riista.common.ui.controller.ViewModelLoadStatus
import fi.riista.common.util.LocalDateTimeProvider
import fi.riista.common.util.SystemDateTimeProvider
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow


/**
 * A controller for editing [CommonHarvest] data.
 */
class EditHarvestController internal constructor(
    harvestSeasons: HarvestSeasons,
    currentTimeProvider: LocalDateTimeProvider,
    permitProvider: PermitProvider,
    speciesResolver: SpeciesResolver,
    stringProvider: StringProvider,
) : ModifyHarvestController(harvestSeasons, currentTimeProvider, permitProvider, speciesResolver, stringProvider) {

    constructor(
        harvestSeasons: HarvestSeasons,
        permitProvider: PermitProvider,
        speciesResolver: SpeciesResolver,
        stringProvider: StringProvider,
    ): this(
        harvestSeasons = harvestSeasons,
        currentTimeProvider = SystemDateTimeProvider(),
        permitProvider = permitProvider,
        speciesResolver = speciesResolver,
        stringProvider = stringProvider,
    )

    var editableHarvest: EditableHarvest? = null

    override fun createLoadViewModelFlow(refresh: Boolean):
            Flow<ViewModelLoadStatus<ModifyHarvestViewModel>> = flow {
        emit(ViewModelLoadStatus.Loading)

        val harvestData = restoredHarvestData
            ?: editableHarvest?.harvest?.copy(
                // transform to latest spec version when editing
                harvestSpecVersion = Constants.HARVEST_SPEC_VERSION
            )

        if (harvestData != null) {
            val viewModel = createViewModel(
                harvest = harvestData,
                permit = permitProvider.getPermit(harvestData),
            ).applyPendingIntents()

            emit(ViewModelLoadStatus.Loaded(viewModel))
        } else {
            emit(ViewModelLoadStatus.LoadFailed)
        }
    }
}

