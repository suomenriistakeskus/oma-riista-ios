package fi.riista.common.domain.srva.sync

import fi.riista.common.database.RiistaDatabase
import fi.riista.common.domain.srva.SrvaEventRepository
import fi.riista.common.domain.srva.model.CommonSrvaEvent
import fi.riista.common.logging.getLogger

interface SrvaEventUpdater {
    suspend fun update(username: String, srvaEvents: List<CommonSrvaEvent>)
}

internal class SrvaEventToDatabaseUpdater(
    database: RiistaDatabase,
) : SrvaEventUpdater {
    private val repository = SrvaEventRepository(database)

    override suspend fun update(username: String, srvaEvents: List<CommonSrvaEvent>) {
        srvaEvents.forEach { event ->
            if (shouldWriteToDatabase(username = username, event = event)) {
                try {
                    repository.upsertSrvaEvent(username = username, srvaEvent = event)
                } catch (e: Exception) {
                    logger.w { "Unable to write event to database" }
                }
            }
        }
    }

    private fun shouldWriteToDatabase(username: String, event: CommonSrvaEvent): Boolean {
        if (event.remoteId != null) {
            val oldEvent = repository.getByRemoteId(username, event.remoteId)
            if (oldEvent != null) {
                return isUpdateNeeded(oldEvent = oldEvent, newEvent = event)
            }
        }
        return true
    }

    private fun isUpdateNeeded(oldEvent: CommonSrvaEvent, newEvent: CommonSrvaEvent): Boolean {
        if (newEvent.srvaSpecVersion > oldEvent.srvaSpecVersion && !oldEvent.modified) {
            return true
        }
        if (newEvent.revision == null || oldEvent.revision == null) {
            return true
        }
        if (newEvent.revision > oldEvent.revision) {
            return true
        }
        return false
    }

    companion object {
        private val logger by getLogger(SrvaEventToDatabaseUpdater::class)
    }
}
