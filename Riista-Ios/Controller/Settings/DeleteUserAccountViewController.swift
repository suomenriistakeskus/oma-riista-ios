import Foundation
import MaterialComponents
import RiistaCommon


@objc class DeleteUserAccountViewController: UIViewController {

    private var loadIndicatorViewController: LoadIndicatorViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "DeleteUserAccount".localized()
    }

    override func loadView() {
        // add constraints according to:
        // https://developer.apple.com/library/archive/technotes/tn2154/_index.html
        view = UIView()
        view.backgroundColor = UIColor.applicationColor(ViewBackground)

        let warningView = WarningView(
            titleText: nil,
            messageText: "DeleteUserAccountMessage".localized(),
            buttonText: "DeleteUserAccount".localized()
        ) {
            self.confirmRequestAccountDeletion()
        }
        warningView.actionButton.applyContainedTheme(withScheme: AppTheme.shared.destructiveButtonScheme())
        view.addSubview(warningView)
        warningView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
    }

    private func confirmRequestAccountDeletion() {
        let messageController = MDCAlertController(
            title: "DeleteUserAccount".localized(),
            message: "DeleteUserAccountQuestion".localized()
        )
        let yesAction = MDCAlertAction(title: "Yes".localized()) { _ in
            CrashlyticsHelper.log(msg: "Delete user account: yes")
            self.requestAccountDeletion()
        }
        let noAction = MDCAlertAction(title: "No".localized()) { _ in
            CrashlyticsHelper.log(msg: "Delete user account: no")
        }
        messageController.addAction(yesAction)
        messageController.addAction(noAction)
        navigationController?.present(messageController, animated: true)
    }

    private func requestAccountDeletion() {
        loadIndicatorViewController = LoadIndicatorViewController().showIn(parentViewController: self)

        RiistaSDK.shared.unregisterAccount { [self] unregisterRequestedDateTime, _ in
            self.loadIndicatorViewController?.hide()

            if let unregisterRequestedDateTime = unregisterRequestedDateTime?.toFoundationDate() {
                self.onAccountDeletionRequested(requestDateTime: unregisterRequestedDateTime)
            } else {
                self.onAccountDeleteRequestFailed()
            }
        }
    }

    private func onAccountDeletionRequested(requestDateTime: Foundation.Date) {
        // prevent further app usage (e.g. synchronizations) now that user has requested account deletion
        AppSync.shared.disableSyncPrecondition(.furtherAppUsageAllowed)

        NotificationCenter.default.post(name: .RequestLogout, object: nil)

        let message = String(
            format: "DeleteUserAccountRequestSentMessageAtTime".localized(),
            requestDateTime.formatDateAndTime()
        )

        WarningViewController(
            navBarTitle: "DeleteUserAccountRequestSentTitleShort".localized(),
            messageTitle: "DeleteUserAccountRequestSentTitle".localized(),
            message: message,
            buttonText: nil,
            buttonOnClicked: nil
        ).showAsNonDismissible(parentViewController: self)
    }

    private func onAccountDeleteRequestFailed() {
        let errorDialog = AlertDialogBuilder.createError(
            message: "NetworkOperationFailed".localized()
        )
        navigationController?.present(errorDialog, animated: true, completion: nil)
    }
}
