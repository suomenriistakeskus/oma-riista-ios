package fi.riista.common.domain.groupHunting

import co.touchlab.stately.concurrency.AtomicReference
import co.touchlab.stately.concurrency.value
import fi.riista.common.domain.groupHunting.dto.HuntingGroupStatusDTO
import fi.riista.common.domain.groupHunting.dto.toHuntingGroupStatus
import fi.riista.common.domain.groupHunting.model.HuntingGroupId
import fi.riista.common.domain.groupHunting.model.HuntingGroupStatus
import fi.riista.common.network.BackendApiProvider
import fi.riista.common.network.NetworkDataFetcher
import fi.riista.common.network.calls.NetworkResponse
import fi.riista.common.network.calls.NetworkResponseData
import fi.riista.common.util.DataFetcher

interface HuntingGroupStatusProvider: DataFetcher {
    val status: HuntingGroupStatus?
}

internal class HuntingGroupStatusFromNetworkProvider(
    backendApiProvider: BackendApiProvider,
    private val huntingGroupId: HuntingGroupId,
) : HuntingGroupStatusProvider,
    NetworkDataFetcher<HuntingGroupStatusDTO>(),
    BackendApiProvider by backendApiProvider {

    private var _status = AtomicReference<HuntingGroupStatus?>(null)
    override val status: HuntingGroupStatus?
        get() = _status.value

    override suspend fun fetchFromNetwork(): NetworkResponse<HuntingGroupStatusDTO> =
        backendAPI.fetchHuntingGroupStatus(huntingGroupId)

    override fun handleSuccess(
        statusCode: Int,
        responseData: NetworkResponseData<out HuntingGroupStatusDTO>
    ) {
        _status.set(responseData.typed.toHuntingGroupStatus())
    }

    override fun handleError401() {
        _status.set(null)
    }
}
