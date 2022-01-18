package fi.riista.common.groupHunting.ui.groupObservation.modify

import fi.riista.common.groupHunting.model.GroupHuntingDay
import fi.riista.common.groupHunting.model.GroupHuntingObservationData
import fi.riista.common.groupHunting.model.HuntingGroupArea
import fi.riista.common.groupHunting.model.HuntingGroupMember
import fi.riista.common.groupHunting.ui.GroupObservationField
import fi.riista.common.ui.dataField.DataFieldViewModel
import fi.riista.common.ui.dataField.DataFields

data class ModifyGroupObservationViewModel(
    internal val observation: GroupHuntingObservationData,
    internal val huntingGroupMembers: List<HuntingGroupMember>,
    internal val huntingDays: List<GroupHuntingDay>,

    override val fields: DataFields<GroupObservationField> = listOf(),
    val observationIsValid: Boolean = false,
    val huntingGroupArea: HuntingGroupArea?,
) : DataFieldViewModel<GroupObservationField>()
