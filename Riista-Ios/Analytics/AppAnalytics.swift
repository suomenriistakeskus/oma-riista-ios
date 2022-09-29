import Foundation
import FirebaseAnalytics


enum AnalyticsEvent {
    case loginBegin(method: LoginMethod)
    case loginSuccess(method: LoginMethod, statusCode: Int)
    case loginFailure(method: LoginMethod, statusCode: Int)

    // Synchronization events at app startup

    /**
     * Should be sent at app startup.
     */
    case startupSynchronizationStatistics(synchronizationMode: String, unsentHarvests: Int)

    /**
     * Should be sent once for each unsent harvest at app startup.
     */
    case startupUnsentHarvest(synchronizationMode: String, harvest: AnalyticsDiaryEntry)

    // Harvest download sync events

    case harvestLoadBegin(synchronizationMode: String)
    case harvestLoadFailed(synchronizationMode: String)
    case harvestLoadCompleted(synchronizationMode: String, updatedHarvestCount: Int, removedHarvestCount: Int)

    // Harvest upload sync events

    case harvestSendBegin(synchronizationMode: String, unsentEntries: UInt)
    case harvestSendFailed(synchronizationMode: String, statusCode: Int)
    case harvestSendCompleted(synchronizationMode: String, successCount: Int, failureCount: Int)

    case harvestSendMissingSpecVersion(harvest: AnalyticsDiaryEntry)
    case harvestSendFailedToSendHarvest(statusCode: Int, harvest: AnalyticsDiaryEntry)
}

enum LoginMethod {
    case legacy
    case riistaSDK
}

// Harvest, but probably also applicable for Observations / SRVAs as well
class AnalyticsDiaryEntry {
    let specVersion: Int
    let speciesCode: Int
    let huntingYear: Int

    init(harvest: DiaryEntry) {
        self.specVersion = harvest.harvestSpecVersion?.intValue ?? -1
        self.speciesCode = harvest.gameSpeciesCode?.intValue ?? -1
        if let pointOfTime = harvest.pointOfTime {
            self.huntingYear = DatetimeUtil.huntingYearContaining(date: pointOfTime)
        } else {
            self.huntingYear = -1
        }
    }

    fileprivate func addToParams(_ params: inout EventParams) {
        params.setDimension(.entrySpecVersion, value: "\(specVersion)")
        params.setDimension(.entrySpeciesCode, value: "\(speciesCode)")
        params.setDimension(.entryHuntingYear, value: "\(huntingYear)")
    }
}

enum AnalyticsUserProperty {
    case synchronizationMode
}

class AppAnalytics {
    class func send(event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

    class func setUserProperty(property: AnalyticsUserProperty, value: String?) {
        Analytics.setUserProperty(value, forName: property.name)
    }
}

/**
 * Event names for analytics
 */
extension AnalyticsEvent {
    var name: String {
        switch self {
        case .loginBegin(_):                            return "login_begin"
        case .loginSuccess(_, _):                       return "login_success"
        case .loginFailure(_, _):                       return "login_failure"

        case .startupSynchronizationStatistics(_, _):   return "startup_synchronization_statistics"
        case .startupUnsentHarvest(_, _):               return "startup_unsent_harvest"

        case .harvestLoadBegin(_):                      return "harvest_load_begin"
        case .harvestLoadFailed(_):                     return "harvest_load_failed"
        case .harvestLoadCompleted(_, _, _):            return "harvest_load_completed"

        case .harvestSendBegin(_, _):                   return "harvest_send_begin"
        case .harvestSendFailed(_, _):                  return "harvest_send_failed"
        case .harvestSendCompleted(_, _, _):            return "harvest_send_completed"
        case .harvestSendMissingSpecVersion(_):         return "harvest_send_missing_spec_version"
        case .harvestSendFailedToSendHarvest(_, _):     return "harvest_send_failed_to_send_harvest"
        }
    }
}

extension AnalyticsUserProperty {
    var name: String {
        switch self {
        case .synchronizationMode:      return "synchronization_mode"
        }
    }
}

/**
 * Event parameters for analytics
 */
extension AnalyticsEvent {
    var parameters: [String : Any]? {
        var params = EventParams()
        switch self {
        case .loginBegin(let method):
            params.setDimension(.loginMethod, value: method.parameterValue)
        case .loginSuccess(let method, let statusCode):
            params.setDimension(.loginMethod, value: method.parameterValue)
            params.setDimension(.statusCode, value: "\(statusCode)")
        case .loginFailure(let method, let statusCode):
            params.setDimension(.loginMethod, value: method.parameterValue)
            params.setDimension(.statusCode, value: "\(statusCode)")

        case .startupSynchronizationStatistics(let synchronizationMode, let unsentHarvests):
            params.setDimension(.synchronizationMode, value: synchronizationMode)
            params.setMetric(.unsentHarvests, value: unsentHarvests)
        case .startupUnsentHarvest(let synchronizationMode, let harvest):
            params.setDimension(.synchronizationMode, value: synchronizationMode)
            harvest.addToParams(&params)

        case .harvestLoadBegin(let synchronizationMode):
            params.setDimension(.synchronizationMode, value: synchronizationMode)
        case .harvestLoadFailed(let synchronizationMode):
            params.setDimension(.synchronizationMode, value: synchronizationMode)
        case .harvestLoadCompleted(let synchronizationMode, let updatedHarvestCount, let removedHarvestCount):
            params.setDimension(.synchronizationMode, value: synchronizationMode)
            params.setMetric(.loadUpdatedCount, value: updatedHarvestCount)
            params.setMetric(.loadRemovedCount, value: removedHarvestCount)

        case .harvestSendBegin(let synchronizationMode, let unsentHarvests):
            params.setDimension(.synchronizationMode, value: synchronizationMode)
            params.setMetric(.unsentHarvests, value: unsentHarvests)
        case .harvestSendFailed(let synchronizationMode, let statusCode):
            params.setDimension(.synchronizationMode, value: synchronizationMode)
            params.setDimension(.statusCode, value: "\(statusCode)")
        case .harvestSendCompleted(let synchronizationMode, let successCount, let failureCount):
            params.setDimension(.synchronizationMode, value: synchronizationMode)
            params.setMetric(.sendSuccessCount, value: successCount)
            params.setMetric(.sendFailureCount, value: failureCount)

        case .harvestSendMissingSpecVersion(let harvest):
            harvest.addToParams(&params)
        case .harvestSendFailedToSendHarvest(let statusCode, let harvest):
            params.setDimension(.statusCode, value: "\(statusCode)")
            harvest.addToParams(&params)
        }

        return params.params
    }
}

fileprivate class EventParams {
    private var _params = [String : Any]()

    var params: [String : Any]? {
        _params.count > 0 ? _params : nil
    }

    func setDimension(_ dimension: Dimension, value: String) {
        _params[dimension.name] = value
    }

    func setMetric(_ metric: Metric, value: Int) {
        _params[metric.name] = value
    }

    func setMetric(_ metric: Metric, value: UInt) {
        _params[metric.name] = value
    }
}

fileprivate enum Dimension {
    case loginMethod
    case statusCode
    case synchronizationMode
    case entrySpecVersion
    case entrySpeciesCode
    case entryHuntingYear

    var name: String {
        switch self {
        case .loginMethod:          return "login_method"
        case .statusCode:           return "status_code"
        case .synchronizationMode:  return "synchronization_mode"
        case .entrySpecVersion:     return "entry_spec_version"
        case .entrySpeciesCode:     return "entry_species_code"
        case .entryHuntingYear:     return "entry_hunting_year"
        }
    }
}

fileprivate enum Metric {
    case unsentHarvests
    case loadUpdatedCount
    case loadRemovedCount
    case sendSuccessCount
    case sendFailureCount

    var name: String {
        switch self {
        case .unsentHarvests:       return "unsent_harvests"
        case .loadUpdatedCount:     return "load_updated_count"
        case .loadRemovedCount:     return "load_removed_count"
        case .sendSuccessCount:     return "send_success_count"
        case .sendFailureCount:     return "send_failure_count"
        }
    }
}

extension LoginMethod {
    var parameterValue: String {
        switch self {
        case .legacy:       return "legacy"
        case .riistaSDK:    return "riistaSdk"
        }
    }
}

