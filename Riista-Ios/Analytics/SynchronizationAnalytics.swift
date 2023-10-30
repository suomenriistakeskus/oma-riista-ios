import Foundation

@objc class SynchronizationAnalytics: NSObject {

    @objc class func sendAppStartupSynchronizationAnalytics() {
        let syncMode = getSynchronizationModeString()
        let unsentHarvests = getUnsentHarvestEntries()

        AppAnalytics.setUserProperty(property: .synchronizationMode, value: syncMode)

        AppAnalytics.send(
            event: .startupSynchronizationStatistics(
                synchronizationMode: syncMode,
                unsentHarvests: unsentHarvests.count
            )
        )

        unsentHarvests.forEach { entry in
            AppAnalytics.send(event: .startupUnsentHarvest(synchronizationMode: syncMode, harvest: entry))
        }
    }

    @objc class func onSynchronizationModeChanged() {
        let synchronizationMode = getSynchronizationModeString()
        AppAnalytics.setUserProperty(property: .synchronizationMode, value: synchronizationMode)
    }


    // MARK: - Harvest download sync

    @objc class func sendLoadingHarvestsBegin() {
        AppAnalytics.send(
            event: .harvestLoadBegin(synchronizationMode: getSynchronizationModeString())
        )
    }

    @objc class func sendLoadingHarvestsFailed() {
        AppAnalytics.send(
            event: .harvestLoadFailed(synchronizationMode: getSynchronizationModeString())
        )
    }

    @objc class func sendLoadingHarvestsCompleted(updatedHarvestCount: Int, removedHarvestCount: Int) {
        AppAnalytics.send(
            event: .harvestLoadCompleted(
                synchronizationMode: getSynchronizationModeString(),
                updatedHarvestCount: updatedHarvestCount,
                removedHarvestCount: removedHarvestCount
            )
        )
    }


    // MARK: - Harvest upload sync

    @objc class func sendHarvestSendBegin(unsentHarvestCount: UInt) {
        AppAnalytics.send(
            event: .harvestSendBegin(
                synchronizationMode: getSynchronizationModeString(),
                unsentEntries: unsentHarvestCount
            )
        )
    }

    @objc class func sendHarvestSendCompleted(successCount: Int, failureCount: Int) {
        AppAnalytics.send(
            event: .harvestSendCompleted(
                synchronizationMode: getSynchronizationModeString(),
                successCount: successCount,
                failureCount: failureCount
            )
        )
    }

    @objc class func sendHarvestSendFailed(statusCode: Int) {
        AppAnalytics.send(
            event: .harvestSendFailed(
                synchronizationMode: getSynchronizationModeString(),
                statusCode: statusCode
            )
        )
    }

    @objc class func sendFailedToSendHarvest(_ harvest: DiaryEntry) {
        sendFailedToSendHarvest(harvest, statusCode: -1)
    }

    @objc class func sendFailedToSendHarvest(_ harvest: DiaryEntry, statusCode: Int) {
        if (harvest.harvestSpecVersion == nil) {
            AppAnalytics.send(
                event: .harvestSendMissingSpecVersion(harvest: AnalyticsDiaryEntry(harvest: harvest))
            )
        } else {
            AppAnalytics.send(
                event: .harvestSendFailedToSendHarvest(statusCode: statusCode,
                                                       harvest: AnalyticsDiaryEntry(harvest: harvest))
            )
        }
    }

    private class func getSynchronizationModeString() -> String {
        switch SynchronizationMode.currentValue {
        case .automatic:   return "automatic"
        case .manual:      return "manual"
        default:           return "unknown"
        }
    }

    private class func getUnsentHarvestEntries() -> [AnalyticsDiaryEntry] {
        let diaryEntries: [DiaryEntryBase] = []

        return diaryEntries.compactMap { diaryEntry in
            if let harvest = diaryEntry as? DiaryEntry {
                return AnalyticsDiaryEntry(harvest: harvest)
            } else {
                return nil
            }
        }
    }
}
