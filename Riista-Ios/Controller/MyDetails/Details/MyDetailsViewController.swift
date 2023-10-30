import Foundation
import RiistaCommon

class MyDetailsViewController: BaseViewController, ListClubMembershipsViewControllerListener {

    private lazy var contentView: MyDetailsContentView = {
        let contentView = MyDetailsContentView()

        contentView.huntingCardButton.onClicked = { [weak self] in
            self?.navigateToHuntingLicense()
        }
        contentView.shootingTestsButton.onClicked = { [weak self] in
            self?.navigateToShootingTests()
        }
        contentView.mhPermitsButton.onClicked = { [weak self] in
            self?.navigateToMhPermits()
        }
        contentView.occupationsButton.onClicked = { [weak self] in
            self?.navigateToOccupations()
        }
        contentView.clubMembershipsButton.onClicked = { [weak self] in
            self?.navigateToClubMemberships()
        }
        contentView.trainingsButton.onClicked = { [weak self] in
            self?.navigateToTrainings()
        }
        return contentView
    }()

    // needed here in order to determine whether there are pending club invitations
    private lazy var huntingClubsController: HuntingClubController =
        HuntingClubController(
            huntingClubsContext: RiistaSDK.shared.currentUserContext.huntingClubsContext,
            usernameProvider: RiistaSDK.shared.currentUserContext,
            huntingClubOccupationsProvider: RiistaSDK.shared.huntingClubOccupations,
            languageProvider: CurrentLanguageProvider(),
            stringProvider: LocalizedStringProvider()
        )

    // should the club invitations be reloaded?
    private var shouldReloadClubInvitations: Bool = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let userInfo = RiistaSettings.userInfo() {
            contentView.updateValues(user: userInfo)
            contentView.occupationsButton.isHidden = userInfo.occupations.isEmpty
            contentView.mhPermitsButton.isEnabled = RiistaSDK.shared.metsahallitusPermits.hasPermits(
                username_: userInfo.username
            )
        }

        title = "MyDetails".localized()

        loadPendingClubInvitations()
    }

    private func loadPendingClubInvitations() {
        if (shouldReloadClubInvitations || !tryIndicatePendingClubInvitations()) {
            huntingClubsController.loadViewModel(
                refresh: shouldReloadClubInvitations,
                completionHandler: handleOnMainThread { [weak self] _ in
                    self?.shouldReloadClubInvitations = false
                    self?.tryIndicatePendingClubInvitations()
                }
            )
        }
    }

    @discardableResult
    private func tryIndicatePendingClubInvitations() -> Bool {
        guard let viewModel = huntingClubsController.getLoadedViewModelOrNull() else {
            return false
        }

        indicatePendingClubInvitations(viewModel: viewModel)
        return true
    }

    private func indicatePendingClubInvitations(viewModel: ListHuntingClubsViewModel) {
        if (viewModel.hasOpenInvitations) {
            contentView.clubMembershipsButton.trailingIcon = UIImage(named: "alert_circle")
            contentView.clubMembershipsButton.trailingIconImageView.tintColor = UIColor.applicationColor(Destructive)
        } else {
            contentView.clubMembershipsButton.trailingIcon = nil
        }
    }

    private func navigateToHuntingLicense() {
        let viewController = HuntingLicenseViewController(userInfo: RiistaSettings.userInfo())
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func navigateToShootingTests() {
        let viewController: ShootingTestsViewController = instantiateViewController(identifier: "ShootingTestsController")
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func navigateToMhPermits() {
        let viewController = ListMetsahallitusPermitsViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func navigateToOccupations() {
        let viewController: OccupationsViewController = instantiateViewController(identifier: "OccupationsController")
        viewController.user = RiistaSettings.userInfo()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func navigateToClubMemberships() {
        let viewController = ListClubMembershipsViewController()
        viewController.listener = self
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func navigateToTrainings() {
        let viewController = ListTrainingsViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func instantiateViewController<T>(identifier: String) -> T {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: identifier) as! T
    }

    override func loadView() {
        // add constraints according to:
        // https://developer.apple.com/library/archive/technotes/tn2154/_index.html
        view = UIView()

        let scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor.applicationColor(ViewBackground)
        scrollView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        // the layoutMargins we're setting may be less than system minimum layout margins..
        viewRespectsSystemMinimumLayoutMargins = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview().inset(12)
        }
    }

    func onClubInvitationAcceptedOrRejected() {
        shouldReloadClubInvitations = true
    }
}
