package fi.riista.common.helpers

import fi.riista.common.database.DatabaseDriverFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.newSingleThreadContext
import kotlinx.coroutines.runBlocking
import kotlin.coroutines.CoroutineContext


@ExperimentalCoroutinesApi
actual val testCoroutineContext: CoroutineContext =
    newSingleThreadContext("testRunner")

@ExperimentalCoroutinesApi
actual fun runBlockingTest(block: suspend CoroutineScope.() -> Unit) =
    runBlocking(testCoroutineContext) { this.block() }

actual fun createDatabaseDriverFactory(): DatabaseDriverFactory {
    return DatabaseDriverFactory()
}
