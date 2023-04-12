package fi.riista.common.domain.observation.sync.network

import fi.riista.common.domain.observation.sync.dto.ObservationDTO
import fi.riista.common.network.NetworkClient
import fi.riista.common.network.calls.NetworkRequest
import fi.riista.common.network.calls.NetworkResponse
import fi.riista.common.util.serializeToJson
import io.ktor.client.request.*
import io.ktor.http.*

internal class UpdateObservation(
    private val observation: ObservationDTO,
) : NetworkRequest<ObservationDTO> {

    override suspend fun request(client: NetworkClient): NetworkResponse<ObservationDTO> {
        val payload = observation.serializeToJson()
        requireNotNull(payload) {
            "Failed to serialize observation data to json"
        }

        return client.request(
            request = {
                put(urlString = "${client.serverBaseAddress}/api/mobile/v2/gamediary/observation/${observation.id}") {
                    accept(ContentType.Application.Json)
                    contentType(ContentType.Application.Json)
                    body = payload
                }
            },
            configureResponseHandler = {
                // nop, default response handling works just fine
            }
        )
    }
}