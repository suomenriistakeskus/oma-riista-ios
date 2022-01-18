import Foundation

enum CooldownStatus {
    case coolingDown
    case success
}

class CooldownGate {
    private let cooldownSeconds: Int
    private(set) var lastSuccessTime: Date?

    init(seconds: Int) {
        self.cooldownSeconds = seconds
        self.lastSuccessTime = nil
    }

    func tryPass() -> CooldownStatus {
        let now = Date()

        var shouldSucceed: Bool
        if let lastSuccessTime = lastSuccessTime {
            shouldSucceed = (DatetimeUtil.secondsSince(from: lastSuccessTime, to: now) ?? 0) > cooldownSeconds
        } else {
            shouldSucceed = true
        }

        if (shouldSucceed) {
            lastSuccessTime = now
        }

        return shouldSucceed ? .success : .coolingDown
    }
}
