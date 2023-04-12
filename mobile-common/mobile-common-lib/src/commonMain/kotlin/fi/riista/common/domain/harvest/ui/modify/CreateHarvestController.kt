package fi.riista.common.domain.harvest.ui.modify

import fi.riista.common.domain.constants.Constants
import fi.riista.common.domain.constants.SpeciesCode
import fi.riista.common.domain.content.SpeciesResolver
import fi.riista.common.domain.groupHunting.model.GroupHuntingPerson
import fi.riista.common.domain.harvest.model.CommonHarvest
import fi.riista.common.domain.harvest.model.CommonHarvestData
import fi.riista.common.domain.model.CommonLocation
import fi.riista.common.domain.model.CommonSpecimenData
import fi.riista.common.domain.model.EntityImages
import fi.riista.common.domain.model.Species
import fi.riista.common.domain.permit.PermitProvider
import fi.riista.common.domain.season.HarvestSeasons
import fi.riista.common.model.BackendEnum
import fi.riista.common.model.ETRMSGeoLocation
import fi.riista.common.model.isInsideFinland
import fi.riista.common.resources.StringProvider
import fi.riista.common.ui.controller.ViewModelLoadStatus
import fi.riista.common.util.LocalDateTimeProvider
import fi.riista.common.util.SystemDateTimeProvider
import fi.riista.common.util.generateMobileClientRefId
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow


/**
 * A controller for creating [CommonHarvest] data.
 */
class CreateHarvestController internal constructor(
    harvestSeasons: HarvestSeasons,
    currentTimeProvider: LocalDateTimeProvider,
    permitProvider: PermitProvider,
    speciesResolver: SpeciesResolver,
    stringProvider: StringProvider,
) : ModifyHarvestController(harvestSeasons, currentTimeProvider, permitProvider, speciesResolver, stringProvider) {

    var initialSpeciesCode: SpeciesCode? = null

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

    /**
     * Can the harvest be moved to current user location?
     *
     * Harvest is not allowed to be moved automatically if its location has been updated
     * manually by the user.
     */
    fun canMoveHarvestToCurrentUserLocation(): Boolean {
        return harvestLocationCanBeUpdatedAutomatically
    }

    /**
     * Tries to move the Harvest to the current user location.
     *
     * Controller will only update the location of the Harvest if user has not explicitly
     * set the location previously and if the given [location] is inside Finland.
     *
     * The return value indicates whether it might be possible to update Harvest location to
     * current user location in the future.
     *
     * @return  True if Harvest location can be changed in the future, false otherwise.
     */
    fun tryMoveHarvestToCurrentUserLocation(location: ETRMSGeoLocation): Boolean {
        if (!location.isInsideFinland()) {
            // It is possible that the exact GPS location is not yet known and the attempted
            // location is outside of Finland. Don't prevent future updates because of this.
            return true
        }

        if (!canMoveHarvestToCurrentUserLocation()) {
            return false
        }

        // don't allow automatic location updates unless the harvest really is loaded
        // - otherwise we might get pending location updates which could become disallowed
        //   when the harvest is being loaded
        if (getLoadedViewModelOrNull() == null) {
            return true
        }

        handleIntent(
            ModifyHarvestIntent.ChangeLocation(
                newLocation = location,
                locationChangedAfterUserInteraction = false
            )
        )
        return true
    }

    override fun createLoadViewModelFlow(refresh: Boolean):
            Flow<ViewModelLoadStatus<ModifyHarvestViewModel>> = flow {
        val existingViewModel = getLoadedViewModelOrNull()
        if (existingViewModel != null) {
            return@flow
        }

        val viewModel = createViewModel(
            harvest = restoredHarvestData ?: createNewHarvest(),
            permit = null,
        ).applyPendingIntents()

        emit(ViewModelLoadStatus.Loaded(viewModel))
    }

    private fun createNewHarvest(): CommonHarvestData {
        return CommonHarvestData(
            localId = null,
            localUrl = null,
            id = null,
            rev = null,
            species = initialSpeciesCode?.let { Species.Known(speciesCode = it) } ?: Species.Unknown,
            location = CommonLocation.Unknown,
            pointOfTime = currentTimeProvider.now(),
            description = null,
            canEdit = true,
            images = EntityImages.noImages(),
            specimens = listOf(CommonSpecimenData().ensureDefaultValuesAreSet()),
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
}

