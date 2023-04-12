package fi.riista.common.domain.harvest.model

import fi.riista.common.domain.dto.HarvestSpecimenDTO
import fi.riista.common.domain.model.CommonSpecimenData
import fi.riista.common.domain.model.GameAge
import fi.riista.common.domain.model.GameAntlersType
import fi.riista.common.domain.model.GameFitnessClass
import fi.riista.common.domain.model.Gender
import fi.riista.common.model.BackendEnum
import kotlinx.serialization.Serializable

typealias CommonHarvestSpecimenId = Long

@Serializable
data class CommonHarvestSpecimen(
    val id: CommonHarvestSpecimenId? = null,
    val rev: Int? = null,
    val gender: BackendEnum<Gender>? = null,
    val age: BackendEnum<GameAge>? = null,
    val weight: Double? = null,
    val weightEstimated: Double? = null,
    val weightMeasured: Double? = null,
    val fitnessClass: BackendEnum<GameFitnessClass>? = null,
    val antlersLost: Boolean? = null,
    val antlersType: BackendEnum<GameAntlersType>? = null,
    val antlersWidth: Int? = null,
    val antlerPointsLeft: Int? = null,
    val antlerPointsRight: Int? = null,
    val antlersGirth: Int? = null,
    val antlersLength: Int? = null,
    val antlersInnerWidth: Int? = null,
    val antlerShaftWidth: Int? = null,
    val notEdible: Boolean? = null,
    val alone: Boolean? = null,
    val additionalInfo: String? = null
)

internal fun CommonHarvestSpecimen.toHarvestSpecimenDTO() : HarvestSpecimenDTO {
    return HarvestSpecimenDTO(
        id = id,
        rev = rev,
        gender = gender?.rawBackendEnumValue,
        age = age?.rawBackendEnumValue,
        weight = weight,
        weightEstimated = weightEstimated,
        weightMeasured = weightMeasured,
        fitnessClass = fitnessClass?.rawBackendEnumValue,
        antlersLost = antlersLost,
        antlersType = antlersType?.rawBackendEnumValue,
        antlersWidth = antlersWidth,
        antlerPointsLeft = antlerPointsLeft,
        antlerPointsRight = antlerPointsRight,
        antlersGirth = antlersGirth,
        antlersLength = antlersLength,
        antlersInnerWidth = antlersInnerWidth,
        antlerShaftWidth = antlerShaftWidth,
        notEdible = notEdible,
        alone = alone,
        additionalInfo = additionalInfo,
    )
}

internal fun CommonHarvestSpecimen.toCommonSpecimenData() =
    CommonSpecimenData(
        remoteId = id,
        revision = rev,
        gender = gender,
        age = age,
        stateOfHealth = null,
        marking = null,
        lengthOfPaw = null,
        widthOfPaw = null,
        weight = weight,
        weightEstimated = weightEstimated,
        weightMeasured = weightMeasured,
        fitnessClass = fitnessClass,
        antlersLost = antlersLost,
        antlersType = antlersType,
        antlersWidth = antlersWidth,
        antlerPointsLeft = antlerPointsLeft,
        antlerPointsRight = antlerPointsRight,
        antlersGirth = antlersGirth,
        antlersLength = antlersLength,
        antlersInnerWidth = antlersInnerWidth,
        antlerShaftWidth = antlerShaftWidth,
        notEdible = notEdible,
        alone = alone,
        additionalInfo = additionalInfo,
    )

internal fun CommonSpecimenData.toCommonHarvestSpecimen() =
    CommonHarvestSpecimen(
        id = remoteId,
        rev = revision,
        gender = gender,
        age = age,
        weight = weight,
        weightEstimated = weightEstimated,
        weightMeasured = weightMeasured,
        fitnessClass = fitnessClass,
        antlersLost = antlersLost,
        antlersType = antlersType,
        antlersWidth = antlersWidth,
        antlerPointsLeft = antlerPointsLeft,
        antlerPointsRight = antlerPointsRight,
        antlersGirth = antlersGirth,
        antlersLength = antlersLength,
        antlersInnerWidth = antlersInnerWidth,
        antlerShaftWidth = antlerShaftWidth,
        notEdible = notEdible,
        alone = alone,
        additionalInfo = additionalInfo,
    )