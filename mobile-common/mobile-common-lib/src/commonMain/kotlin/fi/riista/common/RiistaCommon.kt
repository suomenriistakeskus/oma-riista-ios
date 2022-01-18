package fi.riista.common

import co.touchlab.stately.concurrency.AtomicReference
import fi.riista.common.authentication.EmailService
import fi.riista.common.database.DatabaseDriverFactory
import fi.riista.common.domain.season.HarvestSeasons
import fi.riista.common.dto.UserInfoDTO
import fi.riista.common.logging.LogLevel
import fi.riista.common.logging.Logger
import fi.riista.common.messages.AppStartupMessageHandler
import fi.riista.common.messages.MessageHandler
import fi.riista.common.model.Language
import fi.riista.common.network.*
import fi.riista.common.network.calls.NetworkResponse
import fi.riista.common.network.cookies.CookieData
import fi.riista.common.poi.PoiContext
import fi.riista.common.preferences.PlatformPreferences
import fi.riista.common.preferences.Preferences
import fi.riista.common.remoteSettings.RemoteSettings
import fi.riista.common.userInfo.CurrentUserContextProvider
import fi.riista.common.userInfo.UserContext
import kotlin.jvm.JvmStatic

object RiistaSDK {
    const val SDK_VERSION = "0.0.2"

    private val logLevelHolder = AtomicReference(LogLevel.VERBOSE)
    @JvmStatic
    var logLevel: LogLevel
        get() {
            return logLevelHolder.get()
        }
        set(value) {
            logLevelHolder.set(value)
        }

    // AtomicReference is required because of kotlin native concurrency mode. We want to be
    // able to initialize the SDK from any thread and access initialized SDK from another thread.
    // Without AtomicReference e.g. iOS tests would crash because of InvalidMutabilityException.
    private val INSTANCE_HOLDER = AtomicReference<RiistaSdkBase>(RiistaSdkNotInitialized())

    // a convenience getter for accessing initialized SDK implementation
    internal val INSTANCE: RiistaSdkImpl
        get() = INSTANCE_HOLDER.get().getInitializedRiistaSDK()

    @JvmStatic
    val versionInfo: VersionInfo
        get() = INSTANCE.sdkConfiguration.versionInfo

    /**
     * The UserContext that contains information about
     * - user information load status
     * - user information for the current user (if loaded)
     */
    @JvmStatic
    val currentUserContext: UserContext
        get() {
            return INSTANCE.currentUserContextProvider.userContext
        }

    /**
     * The harvest seasons information
     */
    @JvmStatic
    val harvestSeasons: HarvestSeasons
        get() {
            return INSTANCE.harvestSeasons
        }

    /**
     * The PoiContext that contains information about Points of interest.
     */
    @JvmStatic
    val poiContext: PoiContext
        get() {
            return INSTANCE.poiContext
        }

    /**
     * Initializes the Riista SDK with given information.
     *
     * This function cannot be used directly from apps. Instead [RiistaSdkBuilder]s should
     * be used.
     */
    internal fun initialize(sdkConfiguration: RiistaSdkConfiguration, databaseDriverFactory: DatabaseDriverFactory) {
        Logger.usePlatformLogger.value = true
        INSTANCE_HOLDER.set(RiistaSdkImpl(sdkConfiguration, databaseDriverFactory))
    }

    /**
     * Initializes the Riista SDK with given information + using mock information where possible.
     *
     * This function is intended purely for tests.
     */
    internal fun initializeMocked(
        sdkConfiguration: RiistaSdkConfiguration,
        databaseDriverFactory: DatabaseDriverFactory,
        mockBackendAPI: BackendAPI
    ) {
        Logger.usePlatformLogger.value = false
        INSTANCE_HOLDER.set(RiistaSdkImpl(sdkConfiguration, databaseDriverFactory, mockBackendAPI = mockBackendAPI))
    }

    /**
     * Gets the app startup message handler which is able to
     * - parse given Json as startup message
     * - provide the startup message (if any) to be displayed
     */
    fun appStartupMessageHandler(): AppStartupMessageHandler {
        return INSTANCE.startupMessageHandler
    }

    /**
     * Gets the message handler intended for handling the intro message of the Group Hunting
     * (hunting leader functionality)
     */
    @JvmStatic
    fun groupHuntingIntroMessageHandler(): MessageHandler {
        return INSTANCE.groupHuntingIntroMessageHandler
    }

    /**
     * Gets the RiistaSDK settings which are allowed to be changed from remote source
     * (e.g. Firebase Remote Config or Backend).
     *
     * The settings are stored to permanent storage and thus it is not necessary to
     * update them always although it doesn't hurt either.
     */
    @JvmStatic
    fun remoteSettings(): RemoteSettings {
        return INSTANCE.remoteSettings
    }

    /**
     * Attempts to login using given [username] and [password].
     *
     * If successful, the user info can be later obtained using [currentUserContext]
     */
    suspend fun login(username: String, password: String): NetworkResponse<UserInfoDTO> {
        return INSTANCE.login(username, password)
    }

    /**
     * Instructs the backend to send an email containing a link for resetting the user password.
      */
    suspend fun sendPasswordForgottenEmail(email: String, language: Language): NetworkResponse<Unit> {
        return INSTANCE.sendPasswordForgottenEmail(email, language)
    }

    /**
     * Instructs the backend to start registration process for the user having the given email.
     */
    suspend fun sendStartRegistrationEmail(email: String, language: Language): NetworkResponse<Unit> {
        return INSTANCE.sendStartRegistrationEmail(email, language)
    }

    /**
     * Saves the login credentials in order to allow login to be performed later
     * if needed.
     */
    fun setLoginCredentials(username: String, password: String) {
        INSTANCE.setLoginCredentials(username, password)
    }

    /**
     * Performs the logout. The [currentUserContext] will be cleared.
     */
    fun logout() {
        return INSTANCE.logout()
    }

    /**
     * Gets all network cookies that the network client has stored so far. The cookies
     * are kept in memory only.
     *
     * TODO: remove once applications no longer have application specific network clients
     */
    fun getAllNetworkCookies(): List<CookieData> {
        return INSTANCE.backendAPI.getAllNetworkCookies()
    }
}

/**
 * The base for Riista SDK implementation. Intentionally doesn't expose any functionality
 * as otherwise a dummy implementation would also be required from RiistaSdkNotInitialized.
 */
private interface RiistaSdkBase {
    fun getInitializedRiistaSDK(): RiistaSdkImpl
}

internal class RiistaSdkImpl(
    val sdkConfiguration: RiistaSdkConfiguration,
    internal val databaseDriverFactory: DatabaseDriverFactory,

    /**
     * A mocked [BackendAPI] to be used instead of created one. Should only be passed
     * if running tests.
     */
    val mockBackendAPI: BackendAPI? = null,
): RiistaSdkBase, BackendApiProvider {

    internal val preferences: Preferences by lazy {
        PlatformPreferences()
    }

    internal val startupMessageHandler by lazy {
        AppStartupMessageHandler(sdkConfiguration.versionInfo.appVersion,
                                 sdkConfiguration.platform.name,
                                 preferences)
    }

    internal val groupHuntingIntroMessageHandler by lazy {
        MessageHandler(
                applicationVersion = sdkConfiguration.versionInfo.appVersion,
                platformName = sdkConfiguration.platform.name,
                preferences = preferences,
                storageKey = "GroupHuntingIntroMessageDisplayCount"
        )
    }

    internal val remoteSettings by lazy {
        RemoteSettings(preferences)
    }

    internal val currentUserContextProvider by lazy {
        CurrentUserContextProvider(backendApiProvider = this,
                                   groupHuntingAvailabilityResolver = remoteSettings)
    }

    private val networkClient: NetworkClient by lazy {
        NetworkClient(sdkConfiguration)
    }

    override val backendAPI: BackendAPI by lazy {
        mockBackendAPI ?: AuthenticationAwareBackendAPI(loginService, networkClient)
    }

    internal val loginService by lazy {
        LoginService(networkClient, currentUserContextProvider)
    }

    internal val emailService by lazy {
        EmailService(networkClient)
    }

    internal val harvestSeasons by lazy {
        HarvestSeasons()
    }

    internal val poiContext by lazy {
        PoiContext(backendApiProvider = this)
    }

    override fun getInitializedRiistaSDK(): RiistaSdkImpl = this

    fun setLoginCredentials(username: String, password: String) {
        loginService.setLoginCredentials(username, password)
    }

    suspend fun login(username: String, password: String): NetworkResponse<UserInfoDTO> {
        return loginService.login(username.trim(), password)
    }

    suspend fun sendPasswordForgottenEmail(email: String, language: Language): NetworkResponse<Unit> {
        return emailService.sendPasswordResetEmail(email.trim(), language)
    }

    suspend fun sendStartRegistrationEmail(email: String, language: Language): NetworkResponse<Unit> {
        return emailService.sendStartRegistrationEmail(email.trim(), language)
    }

    fun logout() {
        loginService.logout()
    }
}

private class RiistaSdkNotInitialized : RiistaSdkBase {
    override fun getInitializedRiistaSDK(): RiistaSdkImpl {
        throw AssertionError("RiistaSDK not initialized! Call RiistaSDK.initialize before anything else!")
    }
}