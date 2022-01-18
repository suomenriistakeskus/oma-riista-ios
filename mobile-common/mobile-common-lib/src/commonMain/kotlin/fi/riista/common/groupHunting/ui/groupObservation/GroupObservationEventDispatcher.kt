package fi.riista.common.groupHunting.ui.groupObservation

import fi.riista.common.groupHunting.ui.GroupObservationField
import fi.riista.common.ui.dataField.*

interface GroupObservationStringWithIdEventDispatcher
    : StringWithIdEventDispatcher<GroupObservationField>

interface GroupObservationTimeEventDispatcher
    : LocalTimeEventDispatcher<GroupObservationField>

interface GroupObservationHuntingDayEventDispatcher
    : HuntingDayIdEventDispatcher<GroupObservationField>

interface GroupObservationLocationEventDispatcher
    : LocationEventDispatcher<GroupObservationField>

interface GroupObservationIntEventDispatcher
    : IntEventDispatcher<GroupObservationField>
