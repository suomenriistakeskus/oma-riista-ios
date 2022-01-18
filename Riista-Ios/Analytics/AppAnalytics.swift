import Foundation
import FirebaseAnalytics


enum AnalyticsEvent {
    case loginBegin(method: LoginMethod)
    case loginSuccess(method: LoginMethod, statusCode: Int)
    case loginFailure(method: LoginMethod, statusCode: Int)
}

enum LoginMethod {
    case legacy
    case riistaSDK
}

class AppAnalytics {
    class func send(event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
}

/**
 * Event names for analytics
 */
extension AnalyticsEvent {
    var name: String {
        // Firebase analytics cannot split funnel based on parameter value i.e. we cannot
        // have a "login success/failure" funnel that would allow tracking legacy and
        // riistaSDK logins separately. To fix the issue let's use different analytics
        // names altogether for logging in with legacy code and for riistaSDK. We can then
        // compare results:
        // "login_begin_legacy" -> "login_success_legacy" / "login_failure_legacy"
        // "login_begin_riistaSdk" -> "login_success_riistaSdk" / "login_failure_riistaSdk"

        switch self {
        case .loginBegin(let method):
            return "login_begin_" + method.parameterValue
        case .loginSuccess(let method, _):
            return "login_success_" + method.parameterValue
        case .loginFailure(let method, _):
            return "login_failure_" + method.parameterValue
        }
    }
}

/**
 * Event parameters for analytics
 */
extension AnalyticsEvent {
    var parameters: [String : Any]? {
        var params = [String : Any]()
        switch self {
            case .loginBegin(let method):
                params[ParamNames.loginMethod] = method.parameterValue
                break
            case .loginSuccess(let method, let statusCode):
                params[ParamNames.loginMethod] = method.parameterValue
                params[ParamNames.statusCode] = statusCode
                break
            case .loginFailure(let method, let statusCode):
                params[ParamNames.loginMethod] = method.parameterValue
                params[ParamNames.statusCode] = statusCode
                break
        }

        return params.count > 0 ? params : nil
    }
}

struct ParamNames {
    static let loginMethod = "login_method"
    static let statusCode = "status_code"
}

extension LoginMethod {
    var parameterValue: String {
        switch self {
        case .legacy:       return "legacy"
        case .riistaSDK:    return "riistaSdk"
        }
    }
}

