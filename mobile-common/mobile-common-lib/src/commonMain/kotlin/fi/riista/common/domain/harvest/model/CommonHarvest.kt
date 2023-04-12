package fi.riista.common.domain.harvest.model

import fi.riista.common.domain.groupHunting.model.GroupHuntingPerson
import fi.riista.common.domain.model.DeerHuntingType
import fi.riista.common.domain.model.EntityImages
import fi.riista.common.domain.model.GreySealHuntingMethod
import fi.riista.common.domain.model.HarvestReportState
import fi.riista.common.domain.model.Species
import fi.riista.common.domain.model.StateAcceptedToHarvestPermit
import fi.riista.common.domain.model.asKnownLocation
import fi.riista.common.model.BackendEnum
import fi.riista.common.model.ETRMSGeoLocation
import fi.riista.common.model.LocalDateTime
import kotlinx.serialization.Serializable

typealias CommonHarvestId = Long

@Serializable
data class CommonHarvest(
    val localId: Long?,
    val localUrl: String?, // Used as localId on iOS
    val id: CommonHarvestId?,
    val rev: Int?,
    val species: Species,
    val geoLocation: ETRMSGeoLocation,
    val pointOfTime: LocalDateTime,
    val description: String?,
    val canEdit: Boolean,
    val images: EntityImages,
    val specimens: List<CommonHarvestSpecimen>,
    val amount: Int?,
    val harvestSpecVersion: Int,
    val harvestReportRequired: Boolean,
    val harvestReportState: BackendEnum<HarvestReportState>,
    val permitNumber: String?,
    val permitType: String?,
    val stateAcceptedToHarvestPermit: BackendEnum<StateAcceptedToHarvestPermit>,
    val deerHuntingType: BackendEnum<DeerHuntingType>,
    val deerHuntingOtherTypeDescription: String?,
    val mobileClientRefId: Long?,
    val harvestReportDone: Boolean,
    val rejected: Boolean,
    val feedingPlace: Boolean?,
    val taigaBeanGoose: Boolean?,
    val greySealHuntingMethod: BackendEnum<GreySealHuntingMethod>,
)


internal fun CommonHarvest.toCommonHarvestData(): CommonHarvestData {
    return CommonHarvestData(
        localId = localId,
        localUrl = localUrl,
        id = id,
        rev = rev,
        species = species,
        location = geoLocation.asKnownLocation(),
        pointOfTime = pointOfTime,
        description = description,
        canEdit = canEdit,
        images = images,
        specimens = specimens.map { it.toCommonSpecimenData() },
        amount = amount,
        huntingDayId = null,
        authorInfo = null,
        actorInfo = GroupHuntingPerson.Unknown,
        harvestSpecVersion = harvestSpecVersion,
        harvestReportRequired = harvestReportRequired,
        harvestReportState = harvestReportState,
        permitNumber = permitNumber,
        permitType = permitType,
        stateAcceptedToHarvestPermit = stateAcceptedToHarvestPermit,
        deerHuntingType = deerHuntingType,
        deerHuntingOtherTypeDescription = deerHuntingOtherTypeDescription,
        mobileClientRefId = mobileClientRefId,
        harvestReportDone = harvestReportDone,
        rejected = rejected,
        feedingPlace = feedingPlace,
        taigaBeanGoose = taigaBeanGoose,
        greySealHuntingMethod = greySealHuntingMethod,
    )
}

internal fun CommonHarvestData.toCommonHarvest(): CommonHarvest? {
    val geoLocation = location.etrsLocationOrNull ?: return null

    return CommonHarvest(
        localId = localId,
        localUrl = localUrl,
        id = id,
        rev = rev,
        species = species,
        geoLocation = geoLocation,
        pointOfTime = pointOfTime,
        description = description,
        canEdit = canEdit,
        images = images,
        specimens = specimens.map { it.toCommonHarvestSpecimen() },
        amount = amount,
        harvestSpecVersion = harvestSpecVersion,
        harvestReportRequired = harvestReportRequired,
        harvestReportState = harvestReportState,
        permitNumber = permitNumber,
        permitType = permitType,
        stateAcceptedToHarvestPermit = stateAcceptedToHarvestPermit,
        deerHuntingType = deerHuntingType,
        deerHuntingOtherTypeDescription = deerHuntingOtherTypeDescription,
        mobileClientRefId = mobileClientRefId,
        harvestReportDone = harvestReportDone,
        rejected = rejected,
        feedingPlace = feedingPlace,
        taigaBeanGoose = taigaBeanGoose,
        greySealHuntingMethod = greySealHuntingMethod,
    )
}