package fi.riista.common.network

import fi.riista.common.domain.dto.HunterNumberDTO
import fi.riista.common.domain.dto.MockUserInfo
import fi.riista.common.domain.dto.PersonWithHunterNumberDTO
import fi.riista.common.domain.dto.UserInfoDTO
import fi.riista.common.domain.groupHunting.MockGroupHuntingData
import fi.riista.common.domain.groupHunting.dto.*
import fi.riista.common.domain.groupHunting.model.HuntingGroupId
import fi.riista.common.domain.huntingControl.MockHuntingControlData
import fi.riista.common.domain.huntingControl.dto.HuntingControlHunterInfoDTO
import fi.riista.common.domain.huntingControl.sync.dto.HuntingControlEventCreateDTO
import fi.riista.common.domain.huntingControl.sync.dto.HuntingControlEventDTO
import fi.riista.common.domain.huntingControl.sync.dto.LoadRhysAndHuntingControlEventsDTO
import fi.riista.common.domain.huntingControl.ui.hunterInfo.MockHunterInfoData
import fi.riista.common.domain.huntingclub.MockHuntingClubData
import fi.riista.common.domain.huntingclub.dto.HuntingClubMemberInvitationsDTO
import fi.riista.common.domain.huntingclub.dto.HuntingClubMembershipsDTO
import fi.riista.common.domain.huntingclub.model.HuntingClubMemberInvitationId
import fi.riista.common.domain.model.OrganizationId
import fi.riista.common.domain.observation.MockObservationData
import fi.riista.common.domain.observation.MockObservationPageData
import fi.riista.common.domain.observation.metadata.MockObservationMetadata
import fi.riista.common.domain.observation.metadata.dto.ObservationMetadataDTO
import fi.riista.common.domain.observation.sync.dto.DeletedObservationsDTO
import fi.riista.common.domain.observation.sync.dto.ObservationCreateDTO
import fi.riista.common.domain.observation.sync.dto.ObservationDTO
import fi.riista.common.domain.observation.sync.dto.ObservationPageDTO
import fi.riista.common.domain.poi.MockPoiData
import fi.riista.common.domain.poi.dto.PoiLocationGroupsDTO
import fi.riista.common.domain.srva.MockSrvaEventData
import fi.riista.common.domain.srva.MockSrvaEventPageData
import fi.riista.common.domain.srva.metadata.MockSrvaMetadata
import fi.riista.common.domain.srva.metadata.dto.SrvaMetadataDTO
import fi.riista.common.domain.srva.sync.dto.DeletedSrvaEventsDTO
import fi.riista.common.domain.srva.sync.dto.SrvaEventCreateDTO
import fi.riista.common.domain.srva.sync.dto.SrvaEventDTO
import fi.riista.common.domain.srva.sync.dto.SrvaEventPageDTO
import fi.riista.common.domain.training.dto.TrainingsDTO
import fi.riista.common.domain.training.ui.MockTrainingData
import fi.riista.common.dto.LocalDateTimeDTO
import fi.riista.common.io.CommonFile
import fi.riista.common.model.LocalDateTime
import fi.riista.common.network.calls.NetworkResponse
import fi.riista.common.network.calls.NetworkResponseData
import fi.riista.common.network.cookies.CookieData
import fi.riista.common.util.deserializeFromJson
import io.ktor.utils.io.core.*
import kotlin.reflect.KCallable

data class MockResponse(
    val statusCode: Int? = 200,
    val responseData: String? = null
) {
    companion object {
        fun success(responseData: String?) = MockResponse(responseData = responseData)
        fun success(statusCode: Int?, responseData: String?) = MockResponse(statusCode = statusCode, responseData = responseData)
        fun successWithNoData(statusCode: Int?) = MockResponse(statusCode = statusCode)
        fun error(statusCode: Int?) = MockResponse(statusCode = statusCode)
    }
}

@Suppress("MemberVisibilityCanBePrivate")
open class BackendAPIMock(
    var loginResponse: MockResponse = MockResponse.success(MockUserInfo.Pentti),
    var unregisterAccountResponse: MockResponse = MockResponse.success("\"2023-03-21T15:13:55.320\""),
    var cancelUnregisterAccountResponse: MockResponse = MockResponse.successWithNoData(204),
    var groupHuntingClubsAndGroupsResponse: MockResponse = MockResponse.success(MockGroupHuntingData.OneClub),
    var groupHuntingGroupMembersResponse: MockResponse = MockResponse.success(MockGroupHuntingData.Members),
    var groupHuntingGroupHuntingAreaResponse: MockResponse = MockResponse.success(MockGroupHuntingData.HuntingArea),
    var groupHuntingGroupStatusResponse: MockResponse = MockResponse.success(MockGroupHuntingData.GroupStatus),
    var groupHuntingGroupHuntingDaysResponse: MockResponse = MockResponse.success(MockGroupHuntingData.GroupHuntingDays),
    var groupHuntingCreateHuntingDayResponse: MockResponse = MockResponse.success(MockGroupHuntingData.CreatedGroupHuntingDay),
    var groupHuntingUpdateHuntingDayResponse: MockResponse = MockResponse.success(MockGroupHuntingData.UpdatedFirstHuntingDay),
    var groupHuntingHuntingDayForDeerResponse: MockResponse = MockResponse.success(MockGroupHuntingData.DeerHuntingDay),
    var groupHuntingGameDiaryResponse: MockResponse = MockResponse.success(MockGroupHuntingData.GroupHuntingDiary),
    var groupHuntingCreateHarvestResponse: MockResponse = MockResponse.success(MockGroupHuntingData.CreatedHarvest),
    var groupHuntingAcceptHarvestResponse: MockResponse = MockResponse.success(MockGroupHuntingData.AcceptedHarvest),
    var groupHuntingAcceptObservationResponse: MockResponse = MockResponse.success(MockGroupHuntingData.AcceptedObservation),
    var groupHuntingRejectDiaryEntryResponse: MockResponse = MockResponse.successWithNoData(204),
    var groupHuntingCreateGroupHuntingObservationResponse: MockResponse = MockResponse.success(MockGroupHuntingData.AcceptedObservation),
    var searchPersonByHunterNumberResponse: MockResponse = MockResponse.success(MockGroupHuntingData.PersonWithHunterNumber88888888),
    var huntingClubMembershipResponse: MockResponse = MockResponse.success(MockHuntingClubData.HuntingClubMemberships),
    var huntingClubMemberInvitationsResponse: MockResponse = MockResponse.success(MockHuntingClubData.HuntingClubMemberInvitations),
    var acceptHuntingClubMemberInvitationResponse: MockResponse = MockResponse.successWithNoData(204),
    var rejectHuntingClubMemberInvitationResponse: MockResponse = MockResponse.successWithNoData(204),
    var poiLocationGroupsResponse: MockResponse = MockResponse.success(MockPoiData.PoiLocationGroups),
    var huntingControlRhysResponse: MockResponse = MockResponse.success(MockHuntingControlData.HuntingControlRhys),
    var huntingControlAttachmentThumbnailResponse: MockResponse = MockResponse.success(MockHuntingControlData.AttachmentThumbnail),
    var createHuntingControlEventResponse: MockResponse = MockResponse.success(MockHuntingControlData.CreatedHuntingControlEvent),
    var updateHuntingControlEventReponse: MockResponse = MockResponse.success(MockHuntingControlData.UpdatedHuntingControlEvent),
    var deleteHuntingControlEventAttachmentResponse: MockResponse = MockResponse.successWithNoData(204),
    var uploadHuntingControlEventAttachmentResponse: MockResponse = MockResponse.success(204, "${MockHuntingControlData.UploadedAttachmentRemoteId}"),
    var fetchHuntingControlHunterInfoResponse: MockResponse = MockResponse.success(MockHunterInfoData.HunterInfo),
    var fetchTrainingsResponse: MockResponse = MockResponse.success(MockTrainingData.Trainings),
    var fetchSrvaMetadataResponse: MockResponse = MockResponse.success(MockSrvaMetadata.METADATA_SPEC_VERSION_2),
    var fetchObservationMetadataResponse: MockResponse = MockResponse.success(MockObservationMetadata.METADATA_SPEC_VERSION_4),
    var fetchSrvaEventsResponse: MockResponse = MockResponse.success(MockSrvaEventPageData.srvaPageWithOneEvent),
    var createSrvaEventResponse: MockResponse = MockResponse.success(MockSrvaEventData.srvaEvent),
    var updateSrvaEventResponse: MockResponse = MockResponse.success(MockSrvaEventData.srvaEvent),
    var deleteSrvaEventResponse: MockResponse = MockResponse.successWithNoData(204),
    var fetchDeletedSrvaEventsResponse: MockResponse = MockResponse.success(MockSrvaEventPageData.deletedSrvaEvents),
    var uploadSrvaEventImageResponse: MockResponse = MockResponse.successWithNoData(200),
    var deleteSrvaEventImageResponse: MockResponse = MockResponse.successWithNoData(200),
    var fetchObservationPageResponse: MockResponse = MockResponse.success(MockObservationPageData.observationPage),
    var createObservationResponse: MockResponse = MockResponse.success(MockObservationData.observation),
    var updateObservationResponse: MockResponse = MockResponse.success(MockObservationData.observation),
    var deleteObservationResponse: MockResponse = MockResponse.successWithNoData(204),
    var fetchDeletedObservationsResponse: MockResponse = MockResponse.success(MockObservationPageData.deletedObservations),
    var uploadObservationImageResponse: MockResponse = MockResponse.successWithNoData(200),
    var deleteObservationImageResponse: MockResponse = MockResponse.successWithNoData(200),
) : BackendAPI {
    private val callCounts: MutableMap<String, Int> = mutableMapOf()
    private val callParameters: MutableMap<String, Any> = mutableMapOf()

    override fun getAllNetworkCookies(): List<CookieData> = listOf()

    override fun getNetworkCookies(requestUrl: String): List<CookieData> = listOf()

    override suspend fun login(username: String, password: String, timeoutSeconds: Int): NetworkResponse<UserInfoDTO> {
        increaseCallCount(::login.name)
        return respond(loginResponse)
    }

    override suspend fun unregisterAccount(): NetworkResponse<LocalDateTimeDTO> {
        increaseCallCount(::unregisterAccount.name)
        return respond(unregisterAccountResponse)
    }

    override suspend fun cancelUnregisterAccount(): NetworkResponse<Unit> {
        increaseCallCount(::cancelUnregisterAccount.name)
        return respond(cancelUnregisterAccountResponse)
    }

    override suspend fun fetchGroupHuntingClubsAndHuntingGroups(): NetworkResponse<GroupHuntingClubsAndGroupsDTO> {
        increaseCallCount(::fetchGroupHuntingClubsAndHuntingGroups.name)
        return respond(groupHuntingClubsAndGroupsResponse)
    }

    override suspend fun fetchHuntingGroupMembers(huntingGroupId: HuntingGroupId): NetworkResponse<HuntingGroupMembersDTO> {
        increaseCallCount(::fetchHuntingGroupMembers.name)
        return respond(groupHuntingGroupMembersResponse)
    }

    override suspend fun fetchHuntingGroupArea(huntingGroupId: HuntingGroupId): NetworkResponse<HuntingGroupAreaDTO> {
        increaseCallCount(::fetchHuntingGroupArea.name)
        return respond(groupHuntingGroupHuntingAreaResponse)
    }

    override suspend fun fetchHuntingGroupStatus(huntingGroupId: HuntingGroupId): NetworkResponse<HuntingGroupStatusDTO> {
        increaseCallCount(::fetchHuntingGroupStatus.name)
        return respond(groupHuntingGroupStatusResponse)
    }

    override suspend fun fetchHuntingGroupHuntingDays(huntingGroupId: HuntingGroupId): NetworkResponse<GroupHuntingDaysDTO> {
        increaseCallCount(::fetchHuntingGroupHuntingDays.name)
        return respond(groupHuntingGroupHuntingDaysResponse)
    }

    override suspend fun createHuntingGroupHuntingDay(huntingDayDTO: GroupHuntingDayCreateDTO): NetworkResponse<GroupHuntingDayDTO> {
        increaseCallCount(::createHuntingGroupHuntingDay.name)
        callParameters[::createHuntingGroupHuntingDay.name] = huntingDayDTO
        return respond(groupHuntingCreateHuntingDayResponse)
    }

    override suspend fun updateHuntingGroupHuntingDay(huntingDayDTO: GroupHuntingDayUpdateDTO): NetworkResponse<GroupHuntingDayDTO> {
        increaseCallCount(::updateHuntingGroupHuntingDay.name)
        callParameters[::updateHuntingGroupHuntingDay.name] = huntingDayDTO
        return respond(groupHuntingUpdateHuntingDayResponse)
    }

    override suspend fun fetchHuntingGroupHuntingDayForDeer(huntingDayForDeerDTO: GroupHuntingDayForDeerDTO)
            : NetworkResponse<GroupHuntingDayDTO> {
        increaseCallCount(::fetchHuntingGroupHuntingDayForDeer.name)
        callParameters[::fetchGroupHuntingDiary.name] = huntingDayForDeerDTO
        return respond(groupHuntingHuntingDayForDeerResponse)
    }

    override suspend fun fetchGroupHuntingDiary(huntingGroupId: HuntingGroupId): NetworkResponse<GroupHuntingDiaryDTO> {
        increaseCallCount(::fetchGroupHuntingDiary.name)
        return respond(groupHuntingGameDiaryResponse)
    }

    override suspend fun createGroupHuntingHarvest(harvest: GroupHuntingHarvestCreateDTO): NetworkResponse<GroupHuntingHarvestDTO> {
        increaseCallCount(::createGroupHuntingHarvest.name)
        callParameters[::createGroupHuntingHarvest.name] = harvest
        return respond(groupHuntingCreateHarvestResponse)
    }

    override suspend fun createGroupHuntingObservation(observation: GroupHuntingObservationCreateDTO): NetworkResponse<GroupHuntingObservationDTO> {
        increaseCallCount(::createGroupHuntingObservation.name)
        callParameters[::createGroupHuntingObservation.name] = observation
        return respond(groupHuntingCreateGroupHuntingObservationResponse)
    }

    override suspend fun updateGroupHuntingHarvest(harvest: GroupHuntingHarvestDTO): NetworkResponse<GroupHuntingHarvestDTO> {
        increaseCallCount(::updateGroupHuntingHarvest.name)
        callParameters[::updateGroupHuntingHarvest.name] = harvest
        return respond(groupHuntingAcceptHarvestResponse)
    }

    override suspend fun updateGroupHuntingObservation(observation: GroupHuntingObservationUpdateDTO): NetworkResponse<GroupHuntingObservationDTO> {
        increaseCallCount(::updateGroupHuntingObservation.name)
        callParameters[::updateGroupHuntingObservation.name] = observation
        return respond(groupHuntingAcceptObservationResponse)
    }

    override suspend fun rejectGroupHuntingDiaryEntry(rejectDiaryEntryDTO: RejectDiaryEntryDTO): NetworkResponse<Unit> {
        increaseCallCount(::rejectGroupHuntingDiaryEntry.name)
        callParameters[::rejectGroupHuntingDiaryEntry.name] = rejectDiaryEntryDTO
        return respond(groupHuntingRejectDiaryEntryResponse)
    }

    override suspend fun searchPersonByHunterNumber(hunterNumberDTO: HunterNumberDTO): NetworkResponse<PersonWithHunterNumberDTO> {
        increaseCallCount(::searchPersonByHunterNumber.name)
        callParameters[::searchPersonByHunterNumber.name] = hunterNumberDTO
        return if (hunterNumberDTO == "88888888") {
            respond(searchPersonByHunterNumberResponse)
        } else {
            respond(MockResponse.error(404))
        }
    }

    override suspend fun fetchPoiLocationGroups(externalId: String): NetworkResponse<PoiLocationGroupsDTO> {
        increaseCallCount(::fetchPoiLocationGroups.name)
        return respond(poiLocationGroupsResponse)
    }

    override suspend fun fetchTrainings(): NetworkResponse<TrainingsDTO> {
        increaseCallCount(::fetchTrainings.name)
        return respond(fetchTrainingsResponse)
    }

    override suspend fun fetchHuntingClubMemberships(): NetworkResponse<HuntingClubMembershipsDTO> {
        increaseCallCount(::fetchHuntingClubMemberships.name)
        return respond(huntingClubMembershipResponse)
    }

    override suspend fun fetchHuntingClubMemberInvitations(): NetworkResponse<HuntingClubMemberInvitationsDTO> {
        increaseCallCount(::fetchHuntingClubMemberInvitations.name)
        return respond(huntingClubMemberInvitationsResponse)
    }

    override suspend fun acceptHuntingClubMemberInvitation(invitationId: HuntingClubMemberInvitationId): NetworkResponse<Unit> {
        increaseCallCount(::acceptHuntingClubMemberInvitation.name)
        callParameters[::acceptHuntingClubMemberInvitation.name] = invitationId
        return respond(acceptHuntingClubMemberInvitationResponse)
    }

    override suspend fun rejectHuntingClubMemberInvitation(invitationId: HuntingClubMemberInvitationId): NetworkResponse<Unit> {
        increaseCallCount(::rejectHuntingClubMemberInvitation.name)
        callParameters[::rejectHuntingClubMemberInvitation.name] = invitationId
        return respond(rejectHuntingClubMemberInvitationResponse)
    }

    override suspend fun fetchHuntingControlRhys(modifiedAfter: LocalDateTime?): NetworkResponse<LoadRhysAndHuntingControlEventsDTO> {
        increaseCallCount(::fetchHuntingControlRhys.name)
        modifiedAfter?.let {
            callParameters[::fetchHuntingControlRhys.name] = modifiedAfter
        }
        return respond(huntingControlRhysResponse)
    }

    override suspend fun fetchHuntingControlAttachmentThumbnail(attachmentId: Long): NetworkResponse<ByteArray> {
        increaseCallCount(::fetchHuntingControlAttachmentThumbnail.name)
        callParameters[::fetchHuntingControlAttachmentThumbnail.name] = attachmentId
        val response = huntingControlAttachmentThumbnailResponse
        return if (response.statusCode != null) {
            if (response.statusCode in 200..299) {
                if (response.responseData != null) {
                        return NetworkResponse.Success(
                            statusCode = response.statusCode,
                            data = NetworkResponseData(
                                raw = response.responseData,
                                typed = response.responseData.toByteArray()
                            )
                        )
                } else {
                    NetworkResponse.SuccessWithNoData(statusCode = response.statusCode)
                }
            } else {
                NetworkResponse.ResponseError(response.statusCode)
            }
        } else {
            NetworkResponse.NetworkError(exception = null)
        }
    }

    override suspend fun createHuntingControlEvent(
        rhyId: OrganizationId,
        event: HuntingControlEventCreateDTO
    ): NetworkResponse<HuntingControlEventDTO> {
        increaseCallCount(::createHuntingControlEvent.name)
        callParameters[::createHuntingControlEvent.name] = Pair(rhyId, event)
        return respond(createHuntingControlEventResponse)
    }

    override suspend fun updateHuntingControlEvent(
        rhyId: OrganizationId,
        event: HuntingControlEventDTO
    ): NetworkResponse<HuntingControlEventDTO> {
        increaseCallCount(::updateHuntingControlEvent.name)
        callParameters[::updateHuntingControlEvent.name] = Pair(rhyId, event)
        return respond(updateHuntingControlEventReponse)
    }

    override suspend fun deleteHuntingControlEventAttachment(attachmentId: Long): NetworkResponse<Unit> {
        increaseCallCount(::deleteHuntingControlEventAttachment.name)
        callParameters[::deleteHuntingControlEventAttachment.name] = attachmentId
        return respond(deleteHuntingControlEventAttachmentResponse)
    }

    override suspend fun uploadHuntingControlEventAttachment(
        eventRemoteId: Long,
        uuid: String,
        fileName: String,
        contentType: String,
        file: CommonFile,
    ): NetworkResponse<Long> {
        increaseCallCount(::uploadHuntingControlEventAttachment.name)
        callParameters[::uploadHuntingControlEventAttachment.name] = UploadHuntingControlEventAttachmentCallParameters(
            eventRemoteId = eventRemoteId,
            uuid = uuid,
            fileName = fileName,
            contentType = contentType,
            file = file,
        )
        return respond(uploadHuntingControlEventAttachmentResponse)
    }

    override suspend fun fetchHuntingControlHunterInfoByHunterNumber(
        hunterNumber: String,
    ): NetworkResponse<HuntingControlHunterInfoDTO> {
        increaseCallCount(::fetchHuntingControlHunterInfoByHunterNumber.name)
        callParameters[::fetchHuntingControlHunterInfoByHunterNumber.name] = hunterNumber
        return respond(fetchHuntingControlHunterInfoResponse)
    }

    override suspend fun fetchHuntingControlHunterInfoBySsn(ssn: String): NetworkResponse<HuntingControlHunterInfoDTO> {
        increaseCallCount(::fetchHuntingControlHunterInfoBySsn.name)
        callParameters[::fetchHuntingControlHunterInfoBySsn.name] = ssn
        return respond(fetchHuntingControlHunterInfoResponse)
    }

    override suspend fun fetchSrvaEvents(modifiedAfter: LocalDateTime?): NetworkResponse<SrvaEventPageDTO> {
        increaseCallCount(::fetchSrvaEvents.name)
        return respond(fetchSrvaEventsResponse)
    }

    override suspend fun createSrvaEvent(event: SrvaEventCreateDTO): NetworkResponse<SrvaEventDTO> {
        increaseCallCount(::createSrvaEvent.name)
        callParameters[::createSrvaEvent.name] = event
        return respond(createSrvaEventResponse)
    }

    override suspend fun updateSrvaEvent(event: SrvaEventDTO): NetworkResponse<SrvaEventDTO> {
        increaseCallCount(::updateSrvaEvent.name)
        callParameters[::updateSrvaEvent.name] = event
        return respond(updateSrvaEventResponse)
    }

    override suspend fun deleteSrvaEvent(eventRemoteId: Long): NetworkResponse<Unit> {
        increaseCallCount(::deleteSrvaEvent.name)
        callParameters[::deleteSrvaEvent.name] = eventRemoteId
        return respond(deleteSrvaEventResponse)
    }

    override suspend fun fetchDeletedSrvaEvents(deletedAfter: LocalDateTime?): NetworkResponse<DeletedSrvaEventsDTO> {
        increaseCallCount(::fetchDeletedSrvaEventsResponse.name)
        if (deletedAfter != null) {
            callParameters[::fetchDeletedSrvaEvents.name] = deletedAfter
        }
        return respond(fetchDeletedSrvaEventsResponse)
    }

    override suspend fun uploadSrvaEventImage(
        eventRemoteId: Long,
        uuid: String,
        contentType: String,
        file: CommonFile
    ): NetworkResponse<Unit> {
        increaseCallCount(::uploadSrvaEventImage.name)
        callParameters[::uploadSrvaEventImage.name] = UploadImageCallParameters(
            eventRemoteId = eventRemoteId,
            uuid = uuid,
            contentType = contentType,
            file = file,
        )
        return respond(uploadSrvaEventImageResponse)
    }

    override suspend fun deleteSrvaEventImage(imageUuid: String): NetworkResponse<Unit> {
        increaseCallCount(::deleteSrvaEventImage.name)
        callParameters[::deleteSrvaEventImage.name] = imageUuid
        return respond(deleteSrvaEventImageResponse)
    }

    override suspend fun fetchObservations(modifiedAfter: LocalDateTime?): NetworkResponse<ObservationPageDTO> {
        increaseCallCount(::fetchObservations.name)
        modifiedAfter?.let { callParameters[::fetchObservations.name] = it }
        return respond(fetchObservationPageResponse)
    }

    override suspend fun createObservation(observation: ObservationCreateDTO): NetworkResponse<ObservationDTO> {
        increaseCallCount(::createObservation.name)
        callParameters[::createObservation.name] = observation
        return respond(createObservationResponse)
    }

    override suspend fun updateObservation(observation: ObservationDTO): NetworkResponse<ObservationDTO> {
        increaseCallCount(::updateObservation.name)
        callParameters[::updateObservation.name] = observation
        return respond(updateObservationResponse)
    }

    override suspend fun deleteObservation(observationRemoteId: Long): NetworkResponse<Unit> {
        increaseCallCount(::deleteObservation.name)
        callParameters[::deleteObservation.name] = observationRemoteId
        return respond(deleteObservationResponse)
    }

    override suspend fun fetchDeletedObservations(deletedAfter: LocalDateTime?): NetworkResponse<DeletedObservationsDTO> {
        increaseCallCount(::fetchDeletedObservations.name)
        deletedAfter?.let { callParameters[::fetchDeletedObservations.name] }
        return respond(fetchDeletedObservationsResponse)
    }

    override suspend fun uploadObservationImage(
        observationRemoteId: Long,
        uuid: String,
        contentType: String,
        file: CommonFile
    ): NetworkResponse<Unit> {
        increaseCallCount(::uploadObservationImage.name)
        callParameters[::uploadObservationImage.name] = UploadImageCallParameters(
            eventRemoteId = observationRemoteId,
            uuid = uuid,
            contentType = contentType,
            file = file,
        )
        return respond(uploadObservationImageResponse)
    }

    override suspend fun deleteObservationImage(imageUuid: String): NetworkResponse<Unit> {
        increaseCallCount(::deleteObservationImage.name)
        callParameters[::deleteObservationImage.name] = imageUuid
        return respond(deleteObservationImageResponse)
    }

    override suspend fun fetchSrvaMetadata(): NetworkResponse<SrvaMetadataDTO> {
        increaseCallCount(::fetchSrvaMetadata.name)
        return respond(fetchSrvaMetadataResponse)
    }

    override suspend fun fetchObservationMetadata(): NetworkResponse<ObservationMetadataDTO> {
        increaseCallCount(::fetchObservationMetadata.name)
        return respond(fetchObservationMetadataResponse)
    }

    /**
     * Returns how many times a BackendAPI function of this mock class has been called.
     * Usage:
     *
     * val backendAPIMock = BackendAPIMock()
     * assertEquals(1, backendAPIMock.callCount(backendAPIMock::fetchHuntingGroupHuntingDayForDeer.name))
     */
    fun callCount(methodName: String): Int {
        return (callCounts[methodName] ?: 0)
    }

    fun <R> callCount(method: KCallable<R>): Int {
        return callCount(methodName = method.name)
    }

    /**
     * Returns how many times all BackendAPI functions all called combined.
     */
    fun totalCallCount(): Int {
        return callCounts.values.sum()
    }

    /**
     * Returns the last parameter the given method was called with.
     *
     * Only last call is saved.
     */
    fun callParameter(methodName: String): Any? {
        return callParameters[methodName]
    }

    fun <R> callParameter(method: KCallable<R>): Any? {
        return callParameter(methodName = method.name)
    }

    private fun increaseCallCount(methodName: String) {
        callCounts[methodName] = callCount(methodName) + 1
    }

    protected inline fun <reified T> respond(response: MockResponse): NetworkResponse<T> {
        return if (response.statusCode != null) {
            if (response.statusCode in 200..299) {
                if (response.responseData != null) {
                    NetworkResponse.Success(
                            statusCode = response.statusCode,
                            data = NetworkResponseData(
                                    raw = response.responseData,
                                    typed = response.responseData.deserializeFromJson()!!
                            )
                    )
                } else {
                    NetworkResponse.SuccessWithNoData(statusCode = response.statusCode)
                }
            } else {
                NetworkResponse.ResponseError(response.statusCode)
            }
        } else {
            NetworkResponse.NetworkError(exception = null)
        }
    }

    data class UploadHuntingControlEventAttachmentCallParameters(
        val eventRemoteId: Long,
        val uuid: String,
        val fileName: String,
        val contentType: String,
        val file: CommonFile,
    )

    data class UploadImageCallParameters(
        val eventRemoteId: Long,
        val uuid: String,
        val contentType: String,
        val file: CommonFile,
    )
}
