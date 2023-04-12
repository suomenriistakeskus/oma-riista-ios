package fi.riista.common.domain.observation.sync

import co.touchlab.stately.concurrency.AtomicReference
import co.touchlab.stately.concurrency.value
import fi.riista.common.RiistaSDK
import fi.riista.common.database.RiistaDatabase
import fi.riista.common.domain.observation.ObservationOperationResponse
import fi.riista.common.domain.observation.ObservationRepository
import fi.riista.common.domain.observation.model.CommonObservation
import fi.riista.common.domain.observation.sync.dto.toObservationPage
import fi.riista.common.domain.observation.sync.model.ObservationPage
import fi.riista.common.domain.userInfo.CurrentUserContextProvider
import fi.riista.common.io.CommonFileProvider
import fi.riista.common.logging.getLogger
import fi.riista.common.model.LocalDateTime
import fi.riista.common.network.AbstractSynchronizationContext
import fi.riista.common.network.AbstractSynchronizationContextProvider
import fi.riista.common.network.BackendApiProvider
import fi.riista.common.network.SyncDataPiece
import fi.riista.common.network.UserSynchronizationContext
import fi.riista.common.preferences.Preferences
import fi.riista.common.util.LocalDateTimeProvider

internal class ObservationSynchronizationContextProvider(
    private val backendApiProvider: BackendApiProvider,
    private val database: RiistaDatabase,
    private val preferences: Preferences,
    private val localDateTimeProvider: LocalDateTimeProvider,
    private val commonFileProvider: CommonFileProvider,
    private val currentUserContextProvider: CurrentUserContextProvider,
    syncFinishedListener: (suspend () -> Unit)?,
) : AbstractSynchronizationContextProvider(syncFinishedListener = syncFinishedListener) {

    private var userSynchronizationContext: AtomicReference<UserSynchronizationContext?> = AtomicReference(null)

    override val synchronizationContext: ObservationSynchronizationContext?
        get() {
            val username = currentUserContextProvider.userContext.username
            return if (username != null) {
                var synchronizationContext = userSynchronizationContext.value
                if (synchronizationContext == null || synchronizationContext.username != username) {
                    synchronizationContext = UserSynchronizationContext(
                        username = username,
                        synchronizationContext = ObservationSynchronizationContext(
                            backendApiProvider = backendApiProvider,
                            database = database,
                            preferences = preferences,
                            localDateTimeProvider = localDateTimeProvider,
                            username = username,
                            commonFileProvider = commonFileProvider,
                        )
                    ).also {
                        userSynchronizationContext.set(it)
                    }
                }
                return synchronizationContext.synchronizationContext as ObservationSynchronizationContext
            } else {
                null
            }
        }
}

internal class ObservationSynchronizationContext(
    val backendApiProvider: BackendApiProvider,
    database: RiistaDatabase,
    preferences: Preferences,
    localDateTimeProvider: LocalDateTimeProvider,
    val username: String,
    commonFileProvider: CommonFileProvider,
) : AbstractSynchronizationContext(
    preferences = preferences,
    localDateTimeProvider = localDateTimeProvider,
    syncDataPiece = SyncDataPiece.OBSERVATIONS,
) {
    private val repository = ObservationRepository(database)
    private val observationToDatabaseUpdater = ObservationToDatabaseUpdater(database)
    private val observationToNetworkUpdater = ObservationToNetworkUpdater(
        backendApiProvider = backendApiProvider,
        database = database,
    )
    private val deletedObservationsUpdater = DeletedObservationsUpdater(
        backendApiProvider = backendApiProvider,
        database = database,
    )
    private val observationImageUpdater = ObservationImageUpdater(
        backendApiProvider = backendApiProvider,
        database = database,
        commonFileProvider = commonFileProvider,
    )

    override suspend fun doSynchronize() {
        val lastSynchronizationTimeStamp = getLastSynchronizationTimeStamp(suffix = OBSERVATION_FETCH_SUFFIX)
        var timestamp: LocalDateTime? = lastSynchronizationTimeStamp

        val username = RiistaSDK.currentUserContext.username ?: kotlin.run {
            logger.w { "Unable to sync when no logged in user" }
            return
        }

        // Fetch deleted observations from backend and delete those from local DB
        val lastDeleteTimestamp = getLastSynchronizationTimeStamp(suffix = OBSERVATION_DELETE_SUFFIX)
        val deleteTimestamp = deletedObservationsUpdater.fetchFromBackend(username, lastDeleteTimestamp)
        if (deleteTimestamp != null) {
            saveLastSynchronizationTimeStamp(timestamp = deleteTimestamp, suffix = OBSERVATION_DELETE_SUFFIX)
        }

        // Send locally deleted observations
        deletedObservationsUpdater.updateToBackend(username)

        // Fetch data from backend
        do {
            val page = fetchObservationPage(modifiedAfter = timestamp)
            if (page == null) {
                logger.w { "Unable to fetch observations from backend" }
                return
            }
            timestamp = page.latestEntry
            observationToDatabaseUpdater.update(username = username, observations = page.content)
        } while (page?.hasMore == true)

        sendModifiedObservations(username)

        // Send unsent images
        val imagesWithLocalImages = repository.getObservationsWithImagesNeedingUploading(username)
        observationImageUpdater.updateImagesToBackend(username, imagesWithLocalImages)

        if (timestamp != null) {
            saveLastSynchronizationTimeStamp(timestamp = timestamp, suffix = OBSERVATION_FETCH_SUFFIX)
        }
    }

    internal suspend fun sendObservationToBackend(observation: CommonObservation): ObservationOperationResponse {
        val username = RiistaSDK.currentUserContext.username ?: kotlin.run {
            logger.w { "Unable to sync when no logged in user" }
            return ObservationOperationResponse.Error("Unable to sync when no logged in user")
        }

        val sendResponse = observationToNetworkUpdater.sendObservationToBackend(username, observation)

        // todo: consider sending images during background sync (assuming this is called when observation is saved)
        // - should probably be parameterized
        if (sendResponse is ObservationOperationResponse.Success) {
            // disregard possible image upload failures as those can possibly be corrected next time
            // the synchronization is executed
            observationImageUpdater.updateImagesToBackend(username = username, observation = sendResponse.observation)
        }

        return sendResponse
    }

    /**
     * Deletes the specified observation in the backend.
     *
     * Requires the observation to be locally deleted already.
     */
    internal suspend fun deleteObservationInBackend(observation: CommonObservation) {
        if (!observation.deleted) {
            logger.w { "Refusing to delete not-locally-deleted observation in backend." }
            return
        }

        deletedObservationsUpdater.updateToBackend(observation)
    }

    private suspend fun fetchObservationPage(modifiedAfter: LocalDateTime?): ObservationPage? {
        val response = backendApiProvider.backendAPI.fetchObservations(modifiedAfter = modifiedAfter)
        return response.transformSuccessData { _, data ->
            data.typed.toObservationPage()
        }
    }

    private suspend fun sendModifiedObservations(username: String): List<CommonObservation> {
        val events = repository.getModifiedObservations(username = username)
        return observationToNetworkUpdater.update(username, events)
    }

    override fun logger() = logger

    companion object {
        private const val OBSERVATION_FETCH_SUFFIX = "fetch"
        private const val OBSERVATION_DELETE_SUFFIX = "delete"
        private val logger by getLogger(ObservationSynchronizationContext::class)
    }
}
