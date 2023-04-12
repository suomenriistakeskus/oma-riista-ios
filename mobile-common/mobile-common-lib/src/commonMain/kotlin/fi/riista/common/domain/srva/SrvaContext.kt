package fi.riista.common.domain.srva

import fi.riista.common.RiistaSDK
import fi.riista.common.database.RiistaDatabase
import fi.riista.common.domain.model.EntityImage
import fi.riista.common.domain.srva.model.CommonSrvaEvent
import fi.riista.common.domain.srva.sync.SrvaSynchronizationContextProvider
import fi.riista.common.domain.userInfo.CurrentUserContextProvider
import fi.riista.common.domain.userInfo.LoginStatus
import fi.riista.common.io.CommonFileProvider
import fi.riista.common.logging.getLogger
import fi.riista.common.network.BackendApiProvider
import fi.riista.common.network.SyncDataPiece
import fi.riista.common.preferences.Preferences
import fi.riista.common.util.LocalDateTimeProvider

class SrvaContext internal constructor(
    backendApiProvider: BackendApiProvider,
    preferences: Preferences,
    localDateTimeProvider: LocalDateTimeProvider,
    commonFileProvider: CommonFileProvider,
    database: RiistaDatabase,
    private val currentUserContextProvider: CurrentUserContextProvider,
) : BackendApiProvider by backendApiProvider {

    internal constructor(
        backendApiProvider: BackendApiProvider,
        preferences: Preferences,
        localDateTimeProvider: LocalDateTimeProvider,
        commonFileProvider: CommonFileProvider,
        currentUserContextProvider: CurrentUserContextProvider,
    ): this(
        backendApiProvider = backendApiProvider,
        preferences = preferences,
        localDateTimeProvider = localDateTimeProvider,
        commonFileProvider = commonFileProvider,
        database = RiistaSDK.INSTANCE.database,
        currentUserContextProvider = currentUserContextProvider,
    )

    // internal so that it can be accessed from tests
    internal val repository = SrvaEventRepository(database)

    private val syncContextProvider = SrvaSynchronizationContextProvider(
        backendApiProvider = backendApiProvider,
        database = database,
        preferences = preferences,
        localDateTimeProvider = localDateTimeProvider,
        commonFileProvider = commonFileProvider,
        currentUserContextProvider = currentUserContextProvider,
        syncFinishedListener = ::syncFinished,
    )

    private val _srvaEventProvider = SrvaEventFromDatabaseProvider(
        database = database,
        currentUserContextProvider = currentUserContextProvider,
    )
    val srvaEventProvider: SrvaEventProvider = _srvaEventProvider

    private val srvaEventUpdater: SrvaEventUpdater = SrvaEventDatabaseUpdater(
        database = database,
        currentUserContextProvider = currentUserContextProvider,
    )

    fun initialize() {
        RiistaSDK.registerSyncContextProvider(SyncDataPiece.SRVA_EVENTS, syncContextProvider)
        clearWhenUserLoggedOut()
    }

    suspend fun saveSrvaEvent(srvaEvent: CommonSrvaEvent): SrvaEventOperationResponse {
        val response = srvaEventUpdater.saveSrvaEvent(srvaEvent)
        when (response) {
            is SrvaEventOperationResponse.Error,
            is SrvaEventOperationResponse.SaveFailure,
            is SrvaEventOperationResponse.NetworkFailure -> logger.w { "Srva save failed: $response" }
            is SrvaEventOperationResponse.Success -> _srvaEventProvider.forceRefreshOnNextFetch()
        }
        return response
    }

    fun deleteSrvaEvent(srvaEventLocalId: Long?): CommonSrvaEvent? {
        return if (srvaEventLocalId != null && repository.markDeleted(srvaEventLocalId = srvaEventLocalId)) {
            _srvaEventProvider.forceRefreshOnNextFetch()

            repository.getByLocalId(srvaEventLocalId)
        } else {
            null
        }
    }

    internal suspend fun sendSrvaEventToBackend(srvaEvent: CommonSrvaEvent): SrvaEventOperationResponse {
        return syncContextProvider.synchronizationContext?.sendSrvaEventToBackend(srvaEvent)
            ?: SrvaEventOperationResponse.Error("no synchronization context")
    }

    internal suspend fun deleteSrvaEventInBackend(srvaEvent: CommonSrvaEvent) {
        syncContextProvider.synchronizationContext?.deleteSrvaEventInBackend(srvaEvent)
    }

    /**
     * Get all years that have SRVA events. List is not sorted.
     */
    fun getSrvaYears(): List<Int> {
        return when (val user = currentUserContextProvider.userContext.username) {
            null -> emptyList()
            else -> repository.getSrvaYears(user)
        }
    }

    fun getLocalSrvaImageIds(): List<String> {
        currentUserContextProvider.userContext.username?.let { username ->
            return repository.getEventsWithLocalImages(username = username).map { event ->
                event.images.localImages
                    .filter { image ->
                        image.status == EntityImage.Status.LOCAL || image.status == EntityImage.Status.UPLOADED
                    }
                    .mapNotNull { image -> image.serverId }
            }.flatten()
        } ?: return listOf()
    }

    private fun clearWhenUserLoggedOut() {
        currentUserContextProvider.userContext.loginStatus.bindAndNotify {  loginStatus ->
            if (loginStatus is LoginStatus.NotLoggedIn) {
                clear()
            }
        }
    }

    private fun clear() {
        _srvaEventProvider.clear()
    }

    private fun syncFinished() {
        _srvaEventProvider.forceRefreshOnNextFetch()
    }

    companion object {
        private val logger by getLogger(SrvaContext::class)
    }
}
