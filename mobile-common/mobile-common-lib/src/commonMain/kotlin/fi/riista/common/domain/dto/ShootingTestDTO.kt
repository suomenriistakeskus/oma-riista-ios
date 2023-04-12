package fi.riista.common.domain.dto

import fi.riista.common.domain.model.ShootingTest
import fi.riista.common.dto.LocalDateDTO
import fi.riista.common.dto.toLocalDate
import fi.riista.common.model.toBackendEnum
import kotlinx.serialization.Serializable

@Serializable
data class ShootingTestDTO(
    val rhyCode: String,
    val rhyName: String,
    val type: ShootingTestTypeDTO,
    val typeName: String,

    val begin: LocalDateDTO,
    val end: LocalDateDTO,
    val expired: Boolean,
)

fun ShootingTestDTO.toShootingTest(): ShootingTest? {
    return ShootingTest(
        rhyCode = rhyCode,
        rhyName = rhyName,
        type = type.toBackendEnum(),
        typeName = typeName,
        begin = begin.toLocalDate() ?: return null,
        end = end.toLocalDate() ?: return null,
        expired = expired,
    )
}
