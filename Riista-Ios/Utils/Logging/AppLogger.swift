import Foundation

typealias LogBlock = () -> String

fileprivate func getDefaultLogLevel() -> AppLogger.LogLevel {
    switch env {
    case .dev:          return .verbose
    case .staging:      return .verbose
    case .production:   return .warn
    }
}

class AppLogger {
    enum LogLevel: Int {
        case verbose, debug, info, warn, error
    }

    static var logLevel: LogLevel = getDefaultLogLevel()

    private static let timeFormatter: DateFormatter = DateFormatter(safeLocale: ()).apply({ formatter in
        formatter.dateFormat = "HH:mm:ss.SSS"
    })


    private let context: String

    private(set) var enabled: Bool
    var printTimeStamps: Bool

    convenience init(for loggedObject: AnyObject, printTimeStamps: Bool = false) {
        self.init(context: "\(type(of: loggedObject))", printTimeStamps: printTimeStamps)
    }

    init(context: String, printTimeStamps: Bool) {
        self.context = context
        self.enabled = true
        self.printTimeStamps = printTimeStamps
    }

    // MARK: Toggle logging on/off

    func setEnabled(enabled: Bool) -> AppLogger {
        self.enabled = enabled
        return self
    }


    // MARK: Logging

    func v(_ logBlock: LogBlock) {
        log(level: .verbose, logBlock)
    }

    func d(_ logBlock: LogBlock) {
        log(level: .debug, logBlock)
    }

    func i(_ logBlock: LogBlock) {
        log(level: .info, logBlock)
    }

    func w(_ logBlock: LogBlock) {
        log(level: .warn, logBlock)
    }

    func e(_ logBlock: LogBlock) {
        log(level: .error, logBlock)
    }

    @inline(__always) private func log(level: LogLevel, _ logBlock: LogBlock) {
        if (level.rawValue >= Self.logLevel.rawValue) {
            // explicitly include "  --  " as that allows filtering output if needed
            print("\(level.identifier)\(timestampString())  --  \(context): \(logBlock())")
        }
    }

    @inline(__always) private func timestampString() -> String {
        if (!printTimeStamps) {
            return ""
        }

        return "/\(Self.timeFormatter.string(from: Date()))"
    }
}

fileprivate extension AppLogger.LogLevel {
    var identifier: String {
        // colored blocks take the same space as "  " -> align letters
        switch self {
        case .verbose:  return "  V"
        case .debug:    return "  D"
        case .info:     return "\u{1F7E6}I" // 0x1F7E6 = 🟦
        case .warn:     return "\u{1F7E7}W" // 0x1F7E7 = 🟧
        case .error:    return "\u{1F7E5}E" // 0x1F7E5 = 🟥
        }
    }
}
