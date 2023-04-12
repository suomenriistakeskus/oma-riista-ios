package fi.riista.common.domain.model

import fi.riista.common.model.BackendEnum
import fi.riista.common.model.LocalDate

@kotlinx.serialization.Serializable
data class ShootingTest(
    val rhyCode: String,
    val rhyName: String,
    val type: BackendEnum<ShootingTestType>,
    val typeName: String,
    val begin: LocalDate,
    val end: LocalDate,
    val expired: Boolean,
)
