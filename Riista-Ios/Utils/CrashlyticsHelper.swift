import Foundation
import FirebaseCrashlytics
import RiistaCommon


/**
 * A helper for sending log events and non-fatal errors to Crashlytics.
 */
@objc class CrashlyticsHelper: NSObject {
    private static var breadcrumbsLogger = AppLogger(context: "Breadcrumbs", printTimeStamps: false)
    private static var helperLogger = AppLogger(for: CrashlyticsHelper.self, printTimeStamps: false)

    /**
     * Logs the breadcrumbs i.e. what has happened right before an error has occurred.
     *
     * Simple logging here. Use Crashlytics directly if formatting is required.
     */
    @objc class func breadcrumb(breadcrumb: String) {
        breadcrumbsLogger.v { breadcrumb }
        Crashlytics.crashlytics().log(breadcrumb)
    }

    /**
     * Logs the context i.e. what has happened right before an error has occurred.
     *
     * Simple logging here. Use Crashlytics directly if formatting is required.
     */
    @objc class func log(msg: String?) {
        if let msg = msg {
            helperLogger.v { msg }

            Crashlytics.crashlytics().log(msg)
        }
    }

    @objc class func sendError(domain: String, code: Int, data: [String : Any]? = nil, error: Error? = nil) {
        let userInfo = appendErrorData(to: data, error: error)

        sendError(error: NSError(domain: domain, code: code, userInfo: userInfo))
    }

    @objc class func sendError(domain: String, code: Int, data: [String : Any]? = nil) {
        sendError(error: NSError(domain: domain, code: code, userInfo: data))
    }

    @objc class func sendError(error: NSError) {
        Crashlytics.crashlytics().record(error: error)
    }

    private class func appendErrorData(to data: [String : Any]?, error: Error?) -> [String : Any]? {
        guard let error = error else { return data }

        var data = data ?? [:]
        data["errorCode"] = (error as NSError).code
        data["errorDescription"] = error.localizedDescription
        return data
    }
}


class CommonCrashlyticsLogger: RiistaCommon.CrashlyticsLogger {
    func log(exception: KotlinThrowable, message: String?) {
        if let message = message {
            CrashlyticsHelper.log(msg: message)
        }

        CrashlyticsHelper.sendError(error: exception.asError() as NSError)
    }
}
