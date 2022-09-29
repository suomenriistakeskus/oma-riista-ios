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
            guard let self = self else { return }

            switch (loadStatus) {
            case is RiistaCommon.LoadStatus.LoadError, is RiistaCommon.LoadStatus.Loaded:
                self.groupHuntingAvailable = RiistaSDK.shared.currentUserContext.groupHuntingContext.groupHuntingAvailable
                break
            default:
                break
            }
        }

        RiistaSDK().currentUserContext.groupHuntingContext.checkAvailabilityAndFetchClubs(refresh: false) { (_, error) in
            print("Completed checking group hunting availability")
            completionHandler?()
        }
    }

    @objc func checkHuntingControlAvailability(refresh: Bool, completionHandler: (() -> Void)? = nil) {
        if (!RiistaSDKHelper.riistaSdkInitialized) {
            print("Not checking hunting control, RiistaSDK not initialized")
            return
        }

        RiistaSDK.shared.currentUserContext.huntingControlContext.huntingControlRhyProvider.loadStatus.bindAndNotify { [weak self] loadStatus in
            guard let self = self else { return }

            switch (loadStatus) {
            case is RiistaCommon.LoadStatus.LoadError, is RiistaCommon.LoadStatus.Loaded:
                self.huntingControlAvailable = RiistaSDK.shared.currentUserContext.huntingControlContext.huntingControlAvailable
                break
            default:
                break
            }
        }

        RiistaSDK().currentUserContext.huntingControlContext.checkAvailability(refresh: refresh) { (_, error) in
            print("Completed checking hunting control availability")
            completionHandler?()
        }
    }
}
