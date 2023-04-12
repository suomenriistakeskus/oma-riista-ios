import Foundation

@objc enum SynchronizationMode: Int, CaseIterable, CustomDebugStringConvertible {
    case manual, automatic

    var debugDescription: String {
        switch self {
        case .manual:       return "SynchronizationMode.manual"
        case .automatic:    return "SynchronizationMode.automatic"
        }
    }

    func isManual() -> Bool {
        self == .manual
    }

    func isAutomatic() -> Bool {
        self == .automatic
    }
}

extension SynchronizationMode {
    // DON'T CHANGE as this is the same value as for the old RiistaSettingsSyncModeKey
    private static let settingsKey = "SyncMode"

    private var valueForSettings: Int {
        // values need to match the ones produced from previously used RiistaSyncMode enum
        switch self {
        case .manual:       return 0
        case .automatic:    return 1
        }
    }

    private static var cachedCurrentValue: SynchronizationMode?

    static var currentValue: SynchronizationMode {
        if (cachedCurrentValue == nil) {
            cachedCurrentValue = loadFromSettings()
        }

        return cachedCurrentValue ?? .automatic
    }

    static func setCurrentValue(_ synchronizationMode: SynchronizationMode) {
        SynchronizationMode.cachedCurrentValue = synchronizationMode

        UserDefaults.standard.set(synchronizationMode.valueForSettings, forKey: settingsKey)
        UserDefaults.standard.synchronize()
    }

    static private func loadFromSettings() -> SynchronizationMode? {
        let userDefaults = UserDefaults.standard
        if (userDefaults.object(forKey: settingsKey) != nil) {
            let modeValueInSettings = userDefaults.integer(forKey: settingsKey)

            return SynchronizationMode.allCases.first { synchronizationMode in
                synchronizationMode.valueForSettings == modeValueInSettings
            }
        }

        return nil
    }
}


// a helper class to be used in objective-c
@objc class SynchronizationModeHelper: NSObject {
    @objc static var currentValue: SynchronizationMode {
        SynchronizationMode.currentValue
    }

    @objc static func setCurrentValue(_ synchronizationMode: SynchronizationMode) {
        SynchronizationMode.setCurrentValue(synchronizationMode)
    }

    @objc static func isManual() -> Bool {
        currentValue == .manual
    }

    @objc static func isAutomatic() -> Bool {
        currentValue == .automatic
    }
}
