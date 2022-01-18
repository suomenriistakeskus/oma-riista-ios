import Foundation


@objc class Timer: NSObject {

    static private var tickTimes = Dictionary<String, Date>()

    static func tick(_ key: String) -> Date {
        let tickTime = Date()
        tickTimes[key] = tickTime
        return tickTime
    }

    static func tick(_ key: String, _ msg: String) {
        print("tick \(key) (\(msg)) at \(tick(key))")
    }

    static func tock(_ key: String) -> TimeInterval? {
        return tock(key, tockTime: Date())
    }

    static private func tock(_ key: String, tockTime: Date) -> TimeInterval? {
        if let tickTime = tickTimes[key] {
            return tockTime.timeIntervalSince(tickTime)
        }

        return nil
    }

    static func tock(_ key: String, _ msg: String) {
        let tockTime = Date()
        if let tockInterval = tock(key, tockTime: tockTime) {
            print("tock \(key) (\(msg)) at \(tockTime) - \(tockInterval) seconds since tick")
        } else {
            print("tock \(key) (\(msg)): no tick.")
        }
    }

    static func clear(_ key: String) {
        tickTimes.removeValue(forKey: key)
    }
}
