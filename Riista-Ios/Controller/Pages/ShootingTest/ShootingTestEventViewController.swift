import UIKit
import OAStackView
import MaterialComponents.MaterialDialogs

class ShootingTestEventViewController: UIViewController, OfficialViewDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var venueLabel: UILabel!
    @IBOutlet weak var sumOfPaymentsLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var reopenButton: UIButton!
    @IBOutlet weak var officialsLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var selectedOfficialsView: OAStackView!
    @IBOutlet weak var availableOfficialsView: OAStackView!

    @IBOutlet weak var startButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var editButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var finishButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reopenButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonAreaHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!

    @IBAction func startEventClick(_ sender: UIButton) {
        let occupationIds = self.selectedOfficials.map { $0.occupationId }

        if (occupationIds.count >= 2) {
            let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController

            ShootingTestManager.startShootingTestEvent(calendarEventId: tabBarVc.calendarEventId!,
                                                       shootingTestEventId: tabBarVc.eventId,
                                                       occupationIds: occupationIds as! Array<Int>)
            { (result:Any?, error:Error?) in
                if (error == nil) {
                    self.setEditingOfficials(enabled: false)
                }
                else {
                    print("startShootingTestEvent failed: " + (error?.localizedDescription)!)
                }
            }
        }
    }

    @IBAction func editEventClick(_ sender: UIButton) {
        self.setEditingOfficials(enabled: true)
    }

    @IBAction func closeEventClick(_ sender: UIButton) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController

        let alert = MDCAlertController(title: nil,
                                       message: String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ConfirmOperationPrompt")))
        alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK"), handler: { action in
            ShootingTestManager.closeShootingTestEvent(eventId: tabBarVc.eventId!)
            { (result:Any?, error:Error?) in
                if (error == nil) {
                    self.refreshEvent()
                }
                else {
                    print("closeShootingTestEvent failed: " + (error?.localizedDescription)!)
                }
            }
        }))
        alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "No"), handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func reopenEventClick(_ sender: UIButton) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController

        let alert = MDCAlertController(title: nil,
                                       message: String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ConfirmOperationPrompt")))
        alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "OK"), handler: { action in
            ShootingTestManager.reopenShootingTestEvent(eventId: tabBarVc.eventId!)
            { (result:Any?, error:Error?) in
                if (error == nil) {
                    self.refreshEvent()
                }
                else {
                    print("reopenShootingTestEvent failed: " + (error?.localizedDescription)!)
                }
            }
        }))
        alert.addAction(MDCAlertAction(title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "No"), handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func cancelEditOfficials( sender: UIButton) {
        self.setEditingOfficials(enabled: false)
    }

    @IBAction func saveEditOfficials( sender: UIButton) {
        let occupationIds = self.selectedOfficials.map { $0.occupationId }

        if (occupationIds.count >= 2) {
            let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController

            ShootingTestManager.updateShootingTestOfficials(calendarEventId: tabBarVc.calendarEventId!,
                                                            shootingTestEventId: tabBarVc.eventId!,
                                                            occupationIds: occupationIds as! Array<Int>)
            { (result:Any?, error:Error?) in
                if (error == nil) {
                    self.setEditingOfficials(enabled: false)
                    self.refreshEvent()
                }
                else {
                    print("closeShootingTestEvent failed: " + (error?.localizedDescription)!)
                }
            }
        }
    }

    internal var isEdit: Bool = false
    internal var hasSelectedOfficials = false
    internal var hasAvailableOfficials = false

    internal var selectedOfficials: [ShootingTestOfficial] = Array()
    internal var availableOfficials: [ShootingTestOfficial] = Array()
    internal var selectedOfficialsMaster: [ShootingTestOfficial] = Array()
    internal var availableOfficialsMaster: [ShootingTestOfficial] = Array()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.scrollView.autoresizingMask = .flexibleHeight
        self.setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateTitle()
        refreshEvent()
        refreshScrollViewHeight()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.setEditingOfficials(enabled: false)
    }

    func updateTitle() {
        let navController = self.navigationController as? RiistaNavigationController
        navController?.changeTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestViewTitle"))
    }

    func refreshEvent() {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        tabBarVc.fetchEvent() { (result:Any?, error:Error?) in
            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let event = try JSONDecoder().decode(ShootingTestCalendarEvent.self, from: json)

                    if (event.isWaitingToStart()) {
                        self.isEdit = true
                    }
                    self.refreshUI(event: event)

                    self.refreshSelectedOfficials(event: event)
                    self.refreshAvailableOfficials(event: event)

                    self.refreshScrollViewHeight()
                }
                catch {
                    print("Failed to parse <ShootingTestCalendarEvent> item")
                }
            }
            else {
                print("fetchEvent failed: " + (error?.localizedDescription)!)
            }
        }
    }

    func refreshSelectedOfficials(event: ShootingTestCalendarEvent) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        tabBarVc.fetchSelectedOfficials() { (result:Array?, error:Error?) in
            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let list = try JSONDecoder().decode([ShootingTestOfficial].self, from: json)

                    self.selectedOfficialsMaster.removeAll()
                    self.selectedOfficialsMaster.insert(contentsOf: list , at: 0)
                    self.hasSelectedOfficials = true

                    self.selectedOfficials.removeAll()
                    self.selectedOfficials.insert(contentsOf: self.selectedOfficialsMaster, at: 0)

                    self.filterAvailableOfficials(event: event)
                }
                catch {
                    print("Failed to parse <ShootingTestOfficial> items")
                }
            }
            else {
                print("listSelectedOfficialsForEvent failed: " + (error?.localizedDescription)!)
            }
        }
    }

    func refreshAvailableOfficials(event: ShootingTestCalendarEvent) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        tabBarVc.fetchAvailableOfficials() { (result:Any?, error:Error?) in
            if (error == nil) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: result!)
                    let list = try JSONDecoder().decode([ShootingTestOfficial].self, from: json)

                    self.availableOfficialsMaster.removeAll()
                    self.availableOfficialsMaster.insert(contentsOf: list , at: 0)
                    self.hasAvailableOfficials = true

                    self.filterAvailableOfficials(event: event)
                }
                catch {
                    print("Failed to parse <ShootingTestOfficial> items")
                }
            }
            else {
                print("listSelectedOfficialsForEvent failed: " + (error?.localizedDescription)!)
            }
        }
    }

    private func filterAvailableOfficials(event: ShootingTestCalendarEvent) {
        if (self.hasAvailableOfficials && (self.hasSelectedOfficials || event.isWaitingToStart())) {
            self.availableOfficials.removeAll()

            for item in self.availableOfficialsMaster {
                if (!self.selectedOfficials.contains(where: {x in x.personId == item.personId})) {
                    self.availableOfficials.append(item)
                }
            }

            refreshSelectedOfficials(officials: self.selectedOfficials)
            refreshAvailableOfficials(officials: self.availableOfficials, visible: event.isWaitingToStart() || self.isEdit)
            self.refreshScrollViewHeight()
        }
    }

    func setupUI() {
        Styles.styleButton(self.startButton)
        Styles.styleNegativeButton(self.editButton)
        Styles.styleNegativeButton(self.finishButton)
        Styles.styleButton(self.reopenButton)

        self.startButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestEventStart"), for: .normal)
        self.editButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestEventEdit"), for: .normal)
        self.finishButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestEventFinish"), for: .normal)
        self.reopenButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestEventReopen"), for: .normal)

        self.officialsLabel.text = RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestOfficialsTitle")

        Styles.styleButton(self.saveButton)
        Styles.styleNegativeButton(self.cancelButton)

        self.cancelButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "Cancel"), for: .normal)
        self.saveButton.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "Save"), for: .normal)
    }

    func refreshUI(event: ShootingTestCalendarEvent) {
        self.titleLabel.text = String(format: "%@%@ ", ShootingTestCalendarEvent.localizedTypeText(type: event.calendarEventType!), event.name != nil ? "\n" + event.name! : "")
        self.dateTimeLabel.text = String(format: "%@ %@ %@",
                                         ShootingTestUtil.serverDateStringToDisplayDate(serverDate: event.date!),
                                         event.beginTime!,
                                         event.endTime == nil ? "" : String(format: "- %@", event.endTime!))
        self.venueLabel.text = String(format: "%@\n%@\n%@",
                                      event.venue?.name == nil ? "" : (event.venue?.name)!,
                                      event.venue?.address?.streetAddress ?? "",
                                      event.venue?.address?.city ?? "")
        self.sumOfPaymentsLabel.text = String(format: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestTotalPaidAmount"),
                                              ShootingTestUtil.currencyFormatter().string(from: event.totalPaidAmount! as NSDecimalNumber)!)
        self.refreshButtonVisibility(event: event)
    }

    func refreshButtonVisibility(event: ShootingTestCalendarEvent) {
        self.startButton.isHidden = !event.isWaitingToStart()
        self.startButtonHeightConstraint.constant = event.isWaitingToStart() ? 50.0 : 0.0
        self.startButton.setNeedsLayout()

        self.editButton.isHidden = !event.isOngoing() && self.isEdit
        self.editButtonHeightConstraint.constant = event.isOngoing() && !self.isEdit ? 50.0 : 0.0
        self.editButton.setNeedsLayout()

        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        let hasEditPermission = (tabBarVc.isUserCoordinator || tabBarVc.isUserSelectedAsOfficial)
        let canCloseEvent = event.isReadyToClose() && !self.isEdit && hasEditPermission
        self.finishButton.isHidden = !canCloseEvent
        self.finishButtonHeightConstraint.constant = canCloseEvent ? 50.0 : 0.0
        self.finishButton.setNeedsLayout()

        self.reopenButton.isHidden = !event.isClosed()
        self.reopenButtonHeightConstraint.constant = event.isClosed() ? 50.0 : 0.0
        self.reopenButton.setNeedsLayout()

        self.refreshButtonsEnabled()

        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }

    func refreshButtonsEnabled() {
        self.startButton.isEnabled = self.selectedOfficials.count >= 2
        self.saveButton.isEnabled = self.selectedOfficials.count >= 2
    }

    func setEditingOfficials(enabled: Bool) {
        self.isEdit = enabled
        self.buttonView.isHidden = !enabled
        self.buttonAreaHeightConstraint.constant = enabled ? 60.0 : 0

        self.availableOfficialsView.isHidden = !enabled

        refreshEvent()
    }

    func refreshAvailableOfficials(officials: [ShootingTestOfficial], visible: Bool) {
        self.availableOfficialsView.isHidden = !visible
        self.availableOfficialsView.axis = .vertical
        self.availableOfficialsView.distribution = OAStackViewDistribution.equalSpacing
        self.availableOfficialsView.alignment = OAStackViewAlignment.fill
        self.availableOfficialsView.spacing = 2

        self.availableOfficialsView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        for official : ShootingTestOfficial in officials {
            let view = ShootingTestOfficialView()
            view.delegate = self
            view.isSelected = false
            view.button.tag = official.occupationId!
            view.nameLabel.text = String(format: "%@ %@", official.firstName!, official.lastName!)
            Styles.styleButton(view.button)
            view.button.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestOfficialAdd"), for: .normal)
            view.button.isHidden = !self.isEdit
            self.availableOfficialsView.addArrangedSubview(view)
        }

        self.availableOfficialsView.translatesAutoresizingMaskIntoConstraints = false
        self.availableOfficialsView.setNeedsLayout()
    }

    func refreshSelectedOfficials(officials: [ShootingTestOfficial]) {
        self.selectedOfficialsView.axis = .vertical
        self.selectedOfficialsView.distribution = OAStackViewDistribution.equalSpacing
        self.selectedOfficialsView.alignment = OAStackViewAlignment.fill
        self.selectedOfficialsView.spacing = 2

        self.selectedOfficialsView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        for official : ShootingTestOfficial in officials {
            let view = ShootingTestOfficialView()
            view.delegate = self
            view.isSelected = true
            view.button.tag = official.occupationId!
            view.nameLabel.text = String(format: "%@ %@", official.firstName!, official.lastName!)
            Styles.styleNegativeButton(view.button)
            view.button.setTitle(RiistaBridgingUtils.RiistaLocalizedString(forkey: "ShootingTestOfficialRemove"), for: .normal)
            view.button.isHidden = !self.isEdit
            self.selectedOfficialsView.addArrangedSubview(view)
        }

        self.selectedOfficialsView.translatesAutoresizingMaskIntoConstraints = false
        self.selectedOfficialsView.setNeedsLayout()
    }

    func refreshScrollViewHeight() {
        var contentRect = CGRect.zero

        for view in scrollView.subviews[0].subviews {
            if (!view.isHidden) {
                contentRect = contentRect.union(view.frame)
            }
        }
        scrollView.contentSize = contentRect.size
        scrollView.setNeedsLayout()
        scrollView.layoutIfNeeded()
    }

    // MARK - OfficialViewDelegate

    func didPressButton(_ isAddAction: Bool, tag: Int) {
        if (isAddAction) {
            let item = self.availableOfficials.first(where: {x in x.occupationId == tag})
            self.selectedOfficials.append(item!)

            let index = self.availableOfficials.firstIndex(where: {x in x.occupationId == tag})
            self.availableOfficials.remove(at: index!)
        }
        else {
            let item = self.selectedOfficials.first(where: {x in x.occupationId == tag})
            self.availableOfficials.append(item!)

            let index = self.selectedOfficials.firstIndex(where: {x in x.occupationId == tag})
            self.selectedOfficials.remove(at: index!)
        }

        self.refreshSelectedOfficials(officials: self.selectedOfficials)
        self.refreshAvailableOfficials(officials: self.availableOfficials, visible: true)

        self.refreshButtonsEnabled()

        self.view.layoutIfNeeded()
    }
}
