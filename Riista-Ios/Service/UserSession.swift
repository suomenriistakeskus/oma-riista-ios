import Foundation
import RiistaCommon

/**
 * Encapsulates the current state of the user session
 */
@objc class UserSession: NSObject {

    // MARK: Session management

    private static var currentSession: UserSession = {
        let currentSession = UserSession()
        return currentSession
    }()

    @objc class func shared() -> UserSession {
        return currentSession
    }

    @objc func clear() {
        UserSession.currentSession = UserSession()
    }


    // MARK: Session information

    @objc private(set) var groupHuntingAvailable: Bool

    private(set) var huntingControlAvailable: Bool

    var groupHuntingContext: RiistaCommon.GroupHuntingContext {
        get {
            RiistaSDK.shared.currentUserContext.groupHuntingContext
        }
    }

    override init() {
        self.groupHuntingAvailable = false
        self.huntingControlAvailable = false
    }

    @objc func checkHuntingDirectorAvailability(completionHandler: (() -> Void)? = nil) {
        if (!RiistaSDKHelper.riistaSdkInitialized) {
            print("Not checking group hunting, RiistaSDK not initialized")
            return
        }

        RiistaSDK.shared.currentUserContext.groupHuntingContext.clubContextsProvider.loadStatus.bindAndNotify { [weak self] loadStatus in
            Thread.onMainThread {
                guard let self = self else { return }

                switch (loadStatus) {
                case is RiistaCommon.LoadStatus.LoadError, is RiistaCommon.LoadStatus.Loaded:
                    self.groupHuntingAvailable = RiistaSDK.shared.currentUserContext.groupHuntingContext.groupHuntingAvailable
                    break
                default:
                    break
                }
            }
        }

        RiistaSDK.shared.currentUserContext.groupHuntingContext.checkAvailabilityAndFetchClubs(
            refresh: false,
            completionHandler: handleOnMainThread { _ in
                print("Completed checking group hunting availability")
                completionHandler?()
            }
        )
    }

    @objc func checkHuntingControlAvailability(refresh: Bool, completionHandler: (() -> Void)? = nil) {
        if (!RiistaSDKHelper.riistaSdkInitialized) {
            print("Not checking hunting control, RiistaSDK not initialized")
            return
        }

        RiistaSDK.shared.huntingControlContext.huntingControlAvailable.bindAndNotify { [weak self] available in
            Thread.onMainThread {
                guard let self = self else { return }
                guard let available = available?.boolValue else { return }

                self.huntingControlAvailable = available
            }
        }

        RiistaSDK.shared.huntingControlContext.checkAvailability(
            completionHandler: handleOnMainThread { _ in
                print("Completed checking hunting control availability")
                completionHandler?()
            }
        )
    }
}
