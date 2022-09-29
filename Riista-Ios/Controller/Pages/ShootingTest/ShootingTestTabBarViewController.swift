import UIKit
import Tabman

fileprivate typealias TabBar = TMBarView<TMHorizontalBarLayout, TabBarButton, TMLineBarIndicator>

class ShootingTestTabBarViewController: BaseTabBarViewController, TMBarDataSource, TMBarDelegate {
    var calendarEventId : Int?
    var eventId : Int?

    var calendarEvent : ShootingTestCalendarEvent?

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

    func setSelectedEvent(calendarEventId : Int, eventId : Int?) {
        self.calendarEventId = calendarEventId
        self.eventId = eventId
    }

    func setEnabled(ongoing: Bool, selectedAsOfficial: Bool, isCoordinator: Bool) {
        for (index, item) in tabBarItems.enumerated() {
            if (index == 0) {
                item.enabled = true
            }
            else if (index == 1 || index == 2) {
                item.enabled = self.eventId != nil && ongoing && (selectedAsOfficial || isCoordinator)
            }
            else if (index == 3) {
                item.enabled = self.eventId != nil && (selectedAsOfficial || isCoordinator)
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
            make.top.equalTo(topLayoutGuide.snp.bottom)
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
        self.fetchEvent() { (result:Dictionary?, error:Error?) in
            // Just to refresh tab view badges
        }
    }

    func fetchEvent(completion: @escaping RiistaJsonCompletion) {
        ShootingTestManager.getShootingTestCalendarEvent(eventId: self.calendarEventId!) { (result:Dictionary?, error:Error?) in
            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let event = try JSONDecoder().decode(ShootingTestCalendarEvent.self, from: json)

                    self.calendarEvent = event
                    self.eventId = self.calendarEvent?.shootingTestEventId

                    let user = RiistaSettings.userInfo()

                    var shootingTestOfficialOccupation: Occupation?
                    var coordinatorOccupation: Occupation?
                    if let rhyId = self.calendarEvent?.rhyId {
                        shootingTestOfficialOccupation = user?.findOccupation(ofType: AppConstants.OccupationType.ShootingTestOfficial, forRhyId: Int32(rhyId))
                        coordinatorOccupation = user?.findOccupation(ofType: AppConstants.OccupationType.Coordinator, forRhyId: Int32(rhyId))
                    }

                    var userSelectedAsOfficial = false
                    if (shootingTestOfficialOccupation != nil) {
                        for official in event.officials! {
                            if (official.occupationId == shootingTestOfficialOccupation?.occupationId.intValue) {
                                userSelectedAsOfficial = true;
                            }
                        }
                    }

                    self.isUserSelectedAsOfficial = userSelectedAsOfficial
                    self.isUserCoordinator = coordinatorOccupation != nil

                    self.setEnabled(ongoing: (self.calendarEvent?.isOngoing())!, selectedAsOfficial: self.isUserSelectedAsOfficial, isCoordinator: self.isUserCoordinator)

                    let queueValue = (self.calendarEvent?.numberOfParticipantsWithNoAttempts)!
                    let paymentsValue = (self.calendarEvent?.numberOfAllParticipants)! - (self.calendarEvent?.numberOfCompletedParticipants)!

                    self.tabBarItems[2].badgeValue = queueValue > 0 ? String(queueValue) : nil
                    self.tabBarItems[3].badgeValue = paymentsValue > 0 ? String(paymentsValue) : nil
                }
                catch {
                    print("Failed to parse <ShootingTestCalendarEvent> item")
                }
            }
            completion(result, error)
        }
    }

    func fetchSelectedOfficials(completion: @escaping RiistaJsonArrayCompletion) {
        if (self.eventId != nil) {
            ShootingTestManager.listSelectedOfficialsForEvent(eventId: self.eventId!)
            { (result:Array?, error:Error?) in
                completion(result, error)
            }
        }
        else {
            print("Cannot fetch selected officials without event details")
        }
    }

    func fetchAvailableOfficials(completion: @escaping RiistaJsonArrayCompletion) {
        if (self.eventId != nil) {
            self.availableOfficialsWithEventId(eventId: self.eventId!) { (result:Array?, error:Error?) in
                completion(result, error)
            }
        }
        else if (self.calendarEvent?.rhyId != nil) {
            self.availableOfficialsWithRhy(rhyId: (self.calendarEvent?.rhyId)!) { (result:Array?, error:Error?) in
                completion(result, error)
            }
        }
        else {
            print("Cannot fetch available officials without event details")
        }
    }

    private func availableOfficialsWithRhy(rhyId: Int, completion: @escaping RiistaJsonArrayCompletion) {
        ShootingTestManager.listAvailableOfficialsForRhy(rhyID: rhyId)
        { (result:Array?, error:Error?) in
            completion(result, error)
        }
    }

    private func availableOfficialsWithEventId(eventId: Int, completion: @escaping RiistaJsonArrayCompletion) {
        ShootingTestManager.listAvailableOfficialsForEvent(eventId: eventId)
        { (result:Array?, error:Error?) in
            completion(result, error)
        }
    }

    func fetchParticipants(completion: @escaping RiistaJsonArrayCompletion) {
        ShootingTestManager.listParticipantsForEvent(eventId: self.eventId!)
        { (result:Array?, error:Error?) in
            completion(result, error)
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
