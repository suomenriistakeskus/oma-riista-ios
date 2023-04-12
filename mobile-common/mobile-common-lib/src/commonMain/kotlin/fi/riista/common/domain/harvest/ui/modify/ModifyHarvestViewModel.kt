package fi.riista.common.domain.harvest.ui.modify

import fi.riista.common.domain.harvest.model.CommonHarvestData
import fi.riista.common.domain.harvest.ui.CommonHarvestField
import fi.riista.common.domain.permit.model.CommonPermit
import fi.riista.common.ui.dataField.DataFieldViewModel
import fi.riista.common.ui.dataField.DataFields

data class ModifyHarvestViewModel internal constructor(
    internal val harvest: CommonHarvestData,
    internal val permit: CommonPermit?,
    override val fields: DataFields<CommonHarvestField> = listOf(),
    val harvestIsValid: Boolean,
): DataFieldViewModel<CommonHarvestField>()

