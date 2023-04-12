package fi.riista.common.domain.observation.sync

import fi.riista.common.database.RiistaDatabase
import fi.riista.common.domain.observation.ObservationRepository
import fi.riista.common.domain.observation.model.CommonObservation
import fi.riista.common.logging.getLogger

interface ObservationUpdater {
    suspend fun update(username: String, observations: List<CommonObservation>)
}

internal class ObservationToDatabaseUpdater(
    database: RiistaDatabase,
) : ObservationUpdater {
    private val repository = ObservationRepository(database)

    override suspend fun update(username: String, observations: List<CommonObservation>) {
        observations.forEach { observation ->
            if (shouldWriteToDatabase(username = username, observation = observation)) {
                try {
                    repository.upsertObservation(username = username, observation = observation)
                } catch (e: Exception) {
                    logger.w { "Unable to write event to database" }
                }
            }
        }
    }

    private fun shouldWriteToDatabase(username: String, observation: CommonObservation): Boolean {
        if (observation.remoteId != null) {
            val oldEvent = repository.getByRemoteId(username, observation.remoteId)
            if (oldEvent != null) {
                return isUpdateNeeded(oldObservation = oldEvent, newObservation = observation)
            }
        }
        return true
    }

    private fun isUpdateNeeded(oldObservation: CommonObservation, newObservation: CommonObservation): Boolean {
        if (newObservation.observationSpecVersion > oldObservation.observationSpecVersion && !oldObservation.modified) {
            return true
        }
        if (newObservation.revision == null || oldObservation.revision == null) {
            return true
        }
        if (newObservation.revision > oldObservation.revision) {
            return true
        }
        return false
    }

    companion object {
        private val logger by getLogger(ObservationToDatabaseUpdater::class)
    }
}
