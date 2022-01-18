import Foundation

/**
 * A helper class for performing login analytics from Objective-C land.
 */
@objc class LoginAnalytics: NSObject {
    let method: LoginMethod

    @objc class func forLegacy() -> LoginAnalytics {
        return LoginAnalytics(method: .legacy)
    }

    @objc class func forRiistaSdk() -> LoginAnalytics {
        return LoginAnalytics(method: .riistaSDK)
    }

    init(method: LoginMethod) {
        self.method = method
    }

    @objc func sendLoginBegin() {
        AppAnalytics.send(event: .loginBegin(method: method))
    }

    @objc func sendLoginSuccess(statusCode: Int) {
        AppAnalytics.send(event: .loginSuccess(method: method, statusCode: statusCode))
    }

    @objc func sendLoginFailure(statusCode: Int) {
        AppAnalytics.send(event: .loginFailure(method: method, statusCode: statusCode))
    }
}
