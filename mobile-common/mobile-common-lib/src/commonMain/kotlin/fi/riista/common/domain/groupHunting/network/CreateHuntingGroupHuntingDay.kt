package fi.riista.common.domain.groupHunting.network

import fi.riista.common.domain.groupHunting.dto.GroupHuntingDayCreateDTO
import fi.riista.common.domain.groupHunting.dto.GroupHuntingDayDTO
import fi.riista.common.network.NetworkClient
import fi.riista.common.network.calls.NetworkRequest
import fi.riista.common.network.calls.NetworkResponse
import fi.riista.common.util.serializeToJson
import io.ktor.client.request.accept
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType

internal class CreateHuntingGroupHuntingDay(
    private val huntingDayDTO: GroupHuntingDayCreateDTO
): NetworkRequest<GroupHuntingDayDTO> {
    override suspend fun request(client: NetworkClient): NetworkResponse<GroupHuntingDayDTO> {
        val payload = huntingDayDTO.serializeToJson()
        requireNotNull(payload) {
            "Failed to serialize hunting day data to json"
        }

        return client.request(
                request = {
                    post(urlString = "${client.serverBaseAddress}/api/mobile/v2/grouphunting/huntingday") {
                        accept(ContentType.Application.Json)
                        contentType(ContentType.Application.Json)
                        setBody(body = payload)
                    }
                },
                configureResponseHandler = {
                    // nop, default response handling works just fine
                }
        )
    }
}