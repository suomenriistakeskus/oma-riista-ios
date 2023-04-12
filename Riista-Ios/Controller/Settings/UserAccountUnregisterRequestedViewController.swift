import Foundation
import RiistaCommon

@objc class UserAccountUnregisterRequestedViewController: UIViewController {
    private static let logger = AppLogger(for: UserAccountUnregisterRequestedViewController.self)

    // once every hour
    static private let notificationCooldown = CooldownGate(seconds: 60*60)

    @discardableResult
    @objc class func notifyIfUnregistrationRequested(
        navigationController: UINavigationController?,
        ignoreCooldown: Bool
    ) -> Bool {
        let userAccountUnregistrationRequestDatetime = RiistaSDK.shared.accountService.userAccountUnregistrationRequestDatetime

        guard let unregisterRequestDateTime = userAccountUnregistrationRequestDatetime?.toFoundationDate(),
            let navigationController = navigationController else {
            logger.v {
                "user account has NOT been requested to be removed"
            }
            return false
        }

        // IMPORTANT:
        // - first attempt notificationCooldown.tryPass() as that updates the cooldown counting
        // - then ignore cooldown result if needed
        //
        // -> following attempts will face the cooldown wall (if not ignoring cooldown)
        if (notificationCooldown.tryPass() == .coolingDown && !ignoreCooldown) {
            logger.d {
                "Not displaying notification (yet)"
            }
            return false
        }

        let viewController = UserAccountUnregisterRequestedViewController(
            unregisterRequestDateTime: unregisterRequestDateTime
        )
        navigationController.pushViewController(viewController, animated: true)

        return true
    }

    private let unregisterRequestDateTime: Foundation.Date

    private var loadIndicatorViewController: LoadIndicatorViewController?

    init(unregisterRequestDateTime: Foundation.Date) {
        self.unregisterRequestDateTime = unregisterRequestDateTime
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        title = "DeleteUserAccountRequestSentTitleShort".localized()
    }

    override func loadView() {
        // add constraints according to:
        // https://developer.apple.com/library/archive/technotes/tn2154/_index.html
        view = UIView()
        view.backgroundColor = UIColor.applicationColor(ViewBackground)

        let message = String(
            format: "DeleteUserAccountRequestSentMessageAtTime".localized(),
            unregisterRequestDateTime.formatDateAndTime()
        )

        let warningView = WarningView(
            titleText: "DeleteUserAccountRequestSentTitle".localized(),
            messageText: message,
            buttonText: "DeleteUserAccountContinueUsing".localized(),
            buttonOnClicked: {
                self.continueUsingService()
            }
        )
        // add a separate button for navigating back
        let backButton = MaterialButton()
        backButton.setTitle("Cancel".localized(), for: .normal)
        backButton.applyOutlinedTheme(withScheme: AppTheme.shared.secondaryButtonScheme())
        backButton.onClicked = {
            self.navigationController?.popViewController(animated: true)
        }
        backButton.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.DefaultButtonHeight).priority(999)
        }
        warningView.buttonContainerView.addView(backButton)

        view.addSubview(warningView)
        warningView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
    }

    private func continueUsingService() {
        loadIndicatorViewController = LoadIndicatorViewController().showIn(parentViewController: self)

        RiistaSDK.shared.cancelUnregisterAccount { [weak self] succeeded, _ in
            guard let self = self else { return }

            self.loadIndicatorViewController?.hide()

            if let succeeded = succeeded, succeeded.boolValue {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.onCancelAccountDeleteRequestFailed()
            }
        }
    }

    private func onCancelAccountDeleteRequestFailed() {
        let errorDialog = AlertDialogBuilder.createError(
            message: "NetworkOperationFailed".localized()
        )
        navigationController?.present(errorDialog, animated: true, completion: nil)
    }
}
