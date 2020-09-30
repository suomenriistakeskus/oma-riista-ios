import UIKit

class ShootingTestTabBarViewController: UITabBarController {
    var calendarEventId : Int?
    var eventId : Int?

    var calendarEvent : ShootingTestCalendarEvent?

    var isUserSelectedAsOfficial : Bool = false
    var isUserCoordinator : Bool = false

    var cachedTabBarHeight: CGFloat?

    func setSelectedEvent(calendarEventId : Int, eventId : Int?) {
        self.calendarEventId = calendarEventId
        self.eventId = eventId
    }

    func setEnabled(ongoing: Bool, selectedAsOfficial: Bool, isCoordinator: Bool) {
        for index in 0..<((self.tabBar.items?.count)!) {
            let item = self.tabBar.items![index] as UITabBarItem
            if (index == 0) {
                item.isEnabled = true
            }
            else if (index == 1 || index == 2) {
                item.isEnabled = self.eventId != nil && ongoing && (selectedAsOfficial || isCoordinator)
            }
            else if (index == 3) {
                item.isEnabled = self.eventId != nil && (selectedAsOfficial || isCoordinator)
            }
            else {
                item.isEnabled = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.cachedTabBarHeight = self.tabBar.frame.height

        self.setupRefreshButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tabBar.items?[0].title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTabEventTitle")
        self.tabBar.items?[1].title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTabRegisterTitle")
        self.tabBar.items?[2].title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTabQueueTitle")
        self.tabBar.items?[3].title = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTabPaymentsTitle")

        styleItems()
    }

    override func viewDidLayoutSubviews() {
        moveTabBarToTop()
        super.viewDidLayoutSubviews()
    }

    func moveTabBarToTop() {
        let tabBarHeight = self.cachedTabBarHeight ?? 49
        self.tabBar.frame = CGRect(x: 0, y: 0, width: self.tabBar.frame.size.width, height: tabBarHeight)
    }

    func styleItems() {
        let attrsNormal = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: getTabLabelFontSize())
        ]
        let attrsSelected = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: getTabLabelFontSize())
        ]

        for index in 0..<((self.tabBar.items?.count)!) {
            let item = self.tabBar.items![index] as UITabBarItem
            item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -16)

            item.setTitleTextAttributes(attrsNormal, for: .normal)
            item.setTitleTextAttributes(attrsSelected, for: .selected)
        }

        self.tabBar.backgroundImage = UIImage().createSelectionIndicator(color: UIColor.applicationColor(ShootingTestQualifiedColor), size: CGSize(width: tabBar.frame.size.width/CGFloat(tabBar.items!.count), height: tabBar.frame.size.height), lineWidth: 1.0)
        self.tabBar.selectionIndicatorImage = UIImage().createSelectionIndicator(color: UIColor.applicationColor(ShootingTestQualifiedColor), size: CGSize(width: tabBar.frame.size.width/CGFloat(tabBar.items!.count), height: tabBar.frame.size.height), lineWidth: 4.0)
    }

    func getTabLabelFontSize() -> CGFloat {
        // on iPhone5 there's no spacing between labels and thus we want smaller font size on that device.
        // Since we're planning on switching MDCTabBarController with scrollable tabs, don't invest too much in finetuning this implementation
        if (UIScreen.main.bounds.height <= 568) { // iPhone 5
            return AppConstants.Font.LabelTiny
        } else {
            // other devices
            return AppConstants.Font.LabelSmall
        }
    }

    func setupRefreshButton() {
        let barButton = UIBarButtonItem(image: UIImage(named: "ic_action_refresh.png"), style: .plain, target: self, action: #selector(refreshItemTapped(sender:)))
        self.navigationItem.rightBarButtonItem = barButton
    }

    @objc func refreshItemTapped(sender: UIButton) {
        if (self.selectedIndex == 0) {
            let vc = self.viewControllers?[0] as! ShootingTestEventViewController
            vc.refreshEvent()
        }
        if (self.selectedIndex == 2) {
            let vc = self.viewControllers?[2] as! ShootingTestQueueViewController
            vc.refreshData()
        }
        if (self.selectedIndex == 3) {
            let vc = self.viewControllers?[3] as! ShootingTestPaymentsViewController
            vc.refreshData()
        }
        else {
            self.refreshEvent()
        }
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

                    self.tabBar.items?[2].badgeValue = queueValue > 0 ? String(queueValue) : nil
                    self.tabBar.items?[3].badgeValue = paymentsValue > 0 ? String(paymentsValue) : nil
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
}
