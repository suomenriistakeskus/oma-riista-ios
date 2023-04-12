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


    private let context: String

    private(set) var enabled: Bool

    convenience init(for loggedObject: AnyObject) {
        self.init(context: "\(type(of: loggedObject))")
    }

    init(context: String) {
        self.context = context
        self.enabled = true
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
            print("\(level.char)  --  \(context): \(logBlock())")
        }
    }
}

fileprivate extension AppLogger.LogLevel {
    var char: String {
        switch self {
        case .verbose:  return "V"
        case .debug:    return "D"
        case .info:     return "I"
        case .warn:     return "W"
        case .error:    return "E"
        }
    }
}
