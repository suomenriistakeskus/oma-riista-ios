import Foundation

@objc class BackgroundOperationStatusHelper: NSObject {
    @objc class func setInitialReloginInProgress(_ inProgress: Bool) {
        BackgroundOperationStatus.shared.updateOperationStatus(.initialRelogin, inProgress: inProgress)
    }
}

class BackgroundOperationStatus {
    static let shared = BackgroundOperationStatus()

    private lazy var logger = AppLogger(for: self)

    enum Operation {
        case initialRelogin         // initial relogin attempt after starting the app
        case databaseMigration
        case synchronization
    }

    private var operationsInProgress: Set<Operation> = Set<Operation>()

    private(set) var backgroundOperationInProgress: Bool = false {
        didSet {
            if (backgroundOperationInProgress != oldValue) {
                logger.v { "Background operation in progress = \(backgroundOperationInProgress)" }
                notifyBackgroundOperationStatusChanged()
            }
        }
    }


    // MARK: Updating status

    func startOperation(_ operation: Operation) {
        logger.v { "Start \(operation)" }
        operationsInProgress.insert(operation)
        backgroundOperationInProgress = !operationsInProgress.isEmpty
    }

    func finishOperation(_ operation: Operation) {
        logger.v { "Finish \(operation)" }
        operationsInProgress.remove(operation)
        backgroundOperationInProgress = !operationsInProgress.isEmpty
    }

    func updateOperationStatus(_ operation: Operation, inProgress: Bool) {
        if (inProgress) {
            startOperation(operation)
        } else {
            finishOperation(operation)
        }
    }


    // MARK: Notifications

    private func notifyBackgroundOperationStatusChanged() {
        NotificationCenter.default.post(
            Notification(name: .BackgroundOperationInProgressStatusChanged, object: NSNumber(value: backgroundOperationInProgress))
        )
    }
}
