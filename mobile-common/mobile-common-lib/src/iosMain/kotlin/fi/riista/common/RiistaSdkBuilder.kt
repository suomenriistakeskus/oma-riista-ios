package fi.riista.common

import fi.riista.common.database.DatabaseDriverFactory
import fi.riista.common.logging.CrashlyticsLogger

actual class RiistaSdkBuilder private constructor(
    internal actual var configuration: RiistaSdkConfiguration,
) {

    /**
     * Initializes the RiistaSDK.
     */
    actual fun initializeRiistaSDK() {
        RiistaSDK.initialize(configuration, DatabaseDriverFactory())
    }

    companion object {
        fun with(
            applicationVersion: String,
            buildVersion: String,
            serverBaseAddress: String,
            crashlyticsLogger: CrashlyticsLogger,
        ): RiistaSdkBuilder {
            val configuration = RiistaSdkConfiguration(
                    applicationVersion, buildVersion, serverBaseAddress, crashlyticsLogger)

            return RiistaSdkBuilder(configuration)
        }
    }
}
