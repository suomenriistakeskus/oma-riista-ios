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

    var groupHuntingContext: RiistaCommon.GroupHuntingContext {
        get {
            RiistaSDK().currentUserContext.groupHuntingContext
        }
    }

    override init() {
        self.groupHuntingAvailable = false
    }

    @objc func checkHuntingDirectoryAvailability(completionHandler: (() -> Void)? = nil) {
        if (!RiistaSDKHelper.riistaSdkInitialized) {
            print("Not checking, RiistaSDK not initialized")
            return
        }

        RiistaSDK().currentUserContext.groupHuntingContext.clubContextsProvider.loadStatus.bindAndNotify { [weak self] loadStatus in
            guard let self = self else { return }

            switch (loadStatus) {
            case is RiistaCommon.LoadStatus.LoadError, is RiistaCommon.LoadStatus.Loaded:
                self.groupHuntingAvailable = RiistaSDK().currentUserContext.groupHuntingContext.groupHuntingAvailable
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
}
