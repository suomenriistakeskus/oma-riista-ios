import UIKit
import Tabman
import RiistaCommon

fileprivate typealias TabBar = TMBarView<TMHorizontalBarLayout, TabBarButton, TMLineBarIndicator>


class ShootingTestTabBarViewController: BaseTabBarViewController, TMBarDataSource, TMBarDelegate {
    private lazy var logger = AppLogger(for: self, printTimeStamps: false)

    // todo: get rid of this once other viewcontrollers have been refactored to use shootingTestManager instance
    var calendarEventId : Int? {
        guard let eventId = shootingTestManager.state.calendarEventId else { return nil }
        return Int(eventId)
    }

    // todo: get rid of this once other viewcontrollers have been refactored to use shootingTestManager instance
    var shootingTestEventId : Int? {
        guard let eventId = shootingTestManager.state.shootingTestEventId else { return nil }
        return Int(eventId)
    }

    var shootingTestEvent : CommonShootingTestCalendarEvent?

    let shootingTestManager = ShootingTestManager()

    var isUserSelectedAsOfficial : Bool = false
    var isUserCoordinator : Bool = false

    var cachedTabBarHeight: CGFloat?

    private lazy var customTabBar: TabBar = {
        let bar = TabBar()
        bar.dataSource = self
        bar.delegate = self
        bar.backgroundColor = UIColor.applicationColor(GreyLight)

        bar.layout.contentInset = UIEdgeInsets(top: 0.0, left: 16, bottom: 0.0, right: 16)
        bar.layout.transitionStyle = .snap

        let primaryColor = UIColor.applicationColor(Primary)!
        let disabledColor = UIColor.applicationColor(GreyLight)!
        bar.indicator.tintColor = primaryColor

        bar.buttons.customize { button in
            button.font = UIFont.appFont(fontSize: .small, fontWeight: .semibold)
            button.tintColor = primaryColor
            button.selectedTintColor = primaryColor
            button.enabledTintColor = primaryColor
            button.enabledSelectedTintColor = primaryColor
            button.disabledColor = disabledColor
        }
        return bar
    }()

    private lazy var tabBarItems: [TabBarItem] = {
        let locale = RiistaSettings.locale()
        return [
            TabBarItem(title: "ShootingTestTabEventTitle".localized().uppercased(with: locale), enabled: true),
            TabBarItem(title: "ShootingTestTabRegisterTitle".localized().uppercased(with: locale), enabled: false),
            TabBarItem(title: "ShootingTestTabQueueTitle".localized().uppercased(with: locale), enabled: false),
            TabBarItem(title: "ShootingTestTabPaymentsTitle".localized().uppercased(with: locale), enabled: false)
        ]
    }()

    func setEnabled(ongoing: Bool, selectedAsOfficial: Bool, isCoordinator: Bool) {
        for (index, item) in tabBarItems.enumerated() {
            if (index == 0) {
                item.enabled = true
            }
            else if (index == 1 || index == 2) {
                item.enabled = self.shootingTestEventId != nil && ongoing && (selectedAsOfficial || isCoordinator)
            }
            else if (index == 3) {
                item.enabled = self.shootingTestEventId != nil && (selectedAsOfficial || isCoordinator)
            }
            else {
                item.enabled = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self

        // hide the default tabbar and use custom version instead..
        self.tabBar.isHidden = true

        view.addSubview(customTabBar)
        customTabBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(50) // same height as on storyboard for other view controllers
        }

        reloadTabs()
        customTabBar.update(
            for: 0.0, // first item
            capacity: tabBarItems.count,
            direction: .none,
            animation: TMAnimation(isEnabled: false, duration: 0)
        )
    }

    func refreshEvent() {
        self.fetchEvent() { _, _ in
            // Just to refresh tab view badges
        }
    }

    func fetchEvent(completion: @escaping OnShootingTestEventFetched) {
        shootingTestManager.getShootingTestCalendarEvent() { [weak self] shootingTestEvent, error in
            guard let self = self else { return }
            guard let shootingTestEvent = shootingTestEvent else  {
                self.logger.w { "Failed to fetch shooting test event. Notifying manager." }
                self.shootingTestManager.clearShootingTestEventId()
                self.shootingTestEvent = nil

                completion(nil, error)
                return
            }

            self.shootingTestManager.setShootingTestEventId(
                shootingTestEventId: shootingTestEvent.shootingTestEventId?.int64Value
            )
            self.shootingTestEvent = shootingTestEvent

            let user = RiistaSettings.userInfo()
            var shootingTestOfficialOccupation: Oma_riista.Occupation?
            var coordinatorOccupation: Oma_riista.Occupation?
            if let rhyId = shootingTestEvent.rhyId?.int32Value {
                shootingTestOfficialOccupation = user?.findOccupation(
                    ofType: AppConstants.OccupationType.ShootingTestOfficial,
                    forRhyId: rhyId
                )
                coordinatorOccupation = user?.findOccupation(
                    ofType: AppConstants.OccupationType.Coordinator,
                    forRhyId: rhyId
                )
            }
            var userSelectedAsOfficial = false
            if (shootingTestOfficialOccupation != nil) {
                userSelectedAsOfficial = shootingTestEvent.officials?.contains(where: { official in
                    official.occupationId == shootingTestOfficialOccupation?.occupationId.int64Value
                }) ?? false
            }
            self.isUserSelectedAsOfficial = userSelectedAsOfficial
            self.isUserCoordinator = coordinatorOccupation != nil
            self.setEnabled(
                ongoing: shootingTestEvent.ongoing,
                selectedAsOfficial: self.isUserSelectedAsOfficial,
                isCoordinator: self.isUserCoordinator
            )
            let queueValue = shootingTestEvent.numberOfParticipantsWithNoAttempts
            let paymentsValue = shootingTestEvent.numberOfAllParticipants - shootingTestEvent.numberOfCompletedParticipants

            self.tabBarItems[2].badgeValue = queueValue > 0 ? String(queueValue) : nil
            self.tabBarItems[3].badgeValue = paymentsValue > 0 ? String(paymentsValue) : nil

            completion(shootingTestEvent, nil)
        }
    }

    func fetchSelectedOfficials(completion: @escaping OnShootingTestOfficialsFetched) {
        if (self.shootingTestEventId != nil) {
            shootingTestManager.listSelectedOfficialsForEvent() { officials, error in
                completion(officials, error)
            }
        } else {
            print("Cannot fetch selected officials without event details")
        }
    }

    func fetchAvailableOfficials(completion: @escaping OnShootingTestOfficialsFetched) {
        if (self.shootingTestEventId != nil) {
            shootingTestManager.listAvailableOfficialsForEvent() { officials, error in
                completion(officials, error)
            }
        } else if let rhyId = self.shootingTestEvent?.rhyId?.int64Value {
            shootingTestManager.listAvailableOfficialsForRhy(rhyID: rhyId) { officials, error in
                completion(officials, error)
            }
        } else {
            print("Cannot fetch available officials without event details")
        }
    }

    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        return tabBarItems[index]
    }

    func bar(_ bar: TMBar, didRequestScrollTo index: Int) {
        guard let item = tabBarItems.getOrNil(index: index) else { return }

        if (!item.enabled) {
            print("Item not enabled, nothing to do!")
            return
        }

        selectedIndex = index
        bar.update(
            for: CGFloat(index),
            capacity: tabBarItems.count,
            direction: .none,
            animation: TMAnimation(isEnabled: true, duration: AppConstants.Animations.durationShort)
        )
    }

    private func reloadTabs() {
        customTabBar.reloadData(at: 0...(tabBarItems.count - 1), context: .full)
    }
}


fileprivate class TabBarButton: TMLabelBarButton {

    // cached colors (need to be set from outside).
    // - label is private is super class and thus we have to update tintColor & selectedTintColor
    //   in order to update label color
    var enabledTintColor: UIColor!
    var enabledSelectedTintColor: UIColor!
    var disabledColor: UIColor? {
        didSet {
            updateTextColor()
        }
    }

    override func populate(for item: TMBarItemable) {
        if let tabBarItem = item as? TabBarItem {
            isEnabled = tabBarItem.enabled

            // update text color immediately after setting isEnabled. Updating it during
            // override func update(for selectionState: TMBarButton.SelectionState)
            // is not enough for some reason as items remain in disabled state
            updateTextColor()
        }

        super.populate(for: item)
    }

    private func updateTextColor() {
        guard let disabledColor = disabledColor else {
            return
        }

        // label is private is super class and thus we have to update tintColor & selectedTintColor
        // in order to update label color

        if (isEnabled) {
            tintColor = enabledTintColor
            selectedTintColor = enabledSelectedTintColor
        } else {
            tintColor = disabledColor
            selectedTintColor = disabledColor
        }
    }
}

// tabbar item. Implement TMBarItemable instead of inheriting
// TMBarItem as designated initialized in TMBarItem is private
// --> we have to implement protocol ourselves
fileprivate class TabBarItem: TMBarItemable {
    open var title: String? {
        didSet  {
            setNeedsUpdate()
        }
    }

    open var image: UIImage?  {
        didSet {
            setNeedsUpdate()
        }
    }

    open var selectedImage: UIImage?  {
        didSet {
            setNeedsUpdate()
        }
    }

    open var badgeValue: String? {
        didSet {
            setNeedsUpdate()
        }
    }

    var enabled: Bool = true {
        didSet {
            setNeedsUpdate()
        }
    }

    public var accessibilityLabel: String? {
        didSet {
            setNeedsUpdate()
        }
    }

    public var accessibilityHint: String? {
        didSet {
            setNeedsUpdate()
        }
    }

    public var isAccessibilityElement: Bool { return true }


    // MARK: Init

    public convenience init(title: String, enabled: Bool) {
        self.init(with: title, image: nil, selectedImage: nil, badgeValue: nil, enabled: enabled)
    }

    init(with title: String?, image: UIImage?, selectedImage: UIImage?, badgeValue: String?, enabled: Bool) {
        self.title = title
        self.image = image
        self.selectedImage = selectedImage
        self.badgeValue = badgeValue
        self.enabled = enabled
    }
}
