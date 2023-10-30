import Foundation


class PendingSynchronization {
    private lazy var logger: AppLogger = AppLogger(for: self, printTimeStamps: false)

    enum Flag {
        case syncImmediatelyAfterCurrentSync
        case forceUserContentSync
        case forceContentReload
    }

    private(set) var flags = Set<Flag>()

    private var onChanged: OnChanged

    init(_ onChanged: @escaping OnChanged) {
        self.onChanged = onChanged
    }

    func addFlag(_ flag: Flag) {
        self.flags.insert(flag)
        onChanged()
    }

    func addFlags(_ flags: [Flag]) {
        self.flags.formUnion(flags)
        onChanged()
    }

    func contains(_ requiredFlag: Flag) -> Bool {
        flags.contains(requiredFlag)
    }

    func containsAll(_ requiredFlags: [Flag]) -> Bool {
        let requiredFlagMissing = requiredFlags.contains { requiredFlag in
            self.contains(requiredFlag) == false
        }

        return !requiredFlagMissing
    }

    func clear() {
        flags.removeAll()
        onChanged()
    }
}
