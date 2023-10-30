import Foundation
import Async
import os
typealias PerformTask = (_ onCompleted: @escaping OnCompleted) -> Void

class PeriodicTask {
    private let taskName: String

    private lazy var logger: AppLogger = {
        AppLogger(context: taskName, printTimeStamps: false)
    }()

    /**
     * Callback to be called when task needs to be called
     */
    var onPerformTask: PerformTask?


    /**
     * Has the next task been scheduled?
     */
    private(set) var started: Bool = false

    /**
     * The interval in seconds
     */
    var intervalSeconds: Double

    /**
     * The next scheduled task if any.
     */
    private var scheduledTask: AsyncBlock<Void, Void>?


    convenience init(name: String, intervalSeconds: Double) {
        self.init(name: name, intervalSeconds: intervalSeconds, nil)
    }

    init(name: String, intervalSeconds: Double, _ onPerformTask: PerformTask?) {
        self.taskName = name
        self.intervalSeconds = intervalSeconds
        self.onPerformTask = onPerformTask
    }

    func start(launchFirstTaskNow: Bool) {
        if (started) {
            logger.d { "Periodic task already scheduled. Not launching task nor scheduling." }
            return
        }

        logger.d { "Starting periodic task.." }

        started = true

        if (launchFirstTaskNow) {
            performTaskAndScheduleNextTask()
        } else {
            scheduleNextTaskIfStarted()
        }
    }

    func stop() {
        if (started) {
            logger.d { "Stopping periodic task.." }
        } else {
            logger.v { "Not started, but still ensuring periodic task is stopped." }
        }

        started = false
        scheduledTask?.cancel()
    }

    private func performTaskAndScheduleNextTask() {
        if let performTask = onPerformTask {
            logger.v { "Performing scheduled operation" }
            performTask { [weak self] in
                self?.scheduleNextTaskIfStarted()
            }
        } else {
            logger.w { "No callback for performing task.." }
            scheduleNextTaskIfStarted()
        }
    }

    private func scheduleNextTaskIfStarted() {
        if (!started) {
            logger.d { "Not scheduling next task: not started" }
            return
        }

        logger.v { "Scheduling next task to be performed" }

        scheduledTask = Async.main(after: intervalSeconds) { [weak self] in
            guard let self = self else { return }

            if (self.started) {
                self.performTaskAndScheduleNextTask()
            } else {
                self.logger.d { "No longer started, not performing scheduled task" }
            }
        }
    }
}
