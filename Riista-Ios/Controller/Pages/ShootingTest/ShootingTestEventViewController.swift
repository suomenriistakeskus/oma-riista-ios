import UIKit
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialDialogs
import RiistaCommon

class ShootingTestEventViewController: BaseViewController, OfficialViewDelegate {
    private static var logger = AppLogger(for: ShootingTestEventViewController.self, printTimeStamps: false)

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var venueLabel: UILabel!
    @IBOutlet weak var sumOfPaymentsLabel: UILabel!
    @IBOutlet weak var startButton: MDCButton!
    @IBOutlet weak var editButton: MDCButton!
    @IBOutlet weak var finishButton: MDCButton!
    @IBOutlet weak var reopenButton: MDCButton!
    @IBOutlet weak var officialsLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var selectedOfficialsView: UIStackView!
    @IBOutlet weak var availableOfficialsView: UIStackView!

    @IBOutlet weak var startButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var editButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var finishButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reopenButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonAreaHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var cancelButton: MDCButton!
    @IBOutlet weak var saveButton: MDCButton!

    @IBAction func startEventClick(_ sender: UIButton) {
        let occupationIds = self.selectedOfficials.map { $0.occupationId }

        if (occupationIds.count >= 2) {
            let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
            tabBarVc.shootingTestManager.startShootingTestEvent(
                occupationIds: occupationIds,
                responsibleOfficialOccupationId: self.shootingTestResponsibleOccupationId
            ) { [weak self] success, error in
                guard let self = self else { return }

                if (success) {
                    self.setEditingOfficials(enabled: false)
                } else {
                    print("startShootingTestEvent failed: \(error?.localizedDescription ?? String(describing: error))")
                }
            }
        }
    }

    @IBAction func editEventClick(_ sender: UIButton) {
        self.setEditingOfficials(enabled: true)
    }

    @IBAction func closeEventClick(_ sender: UIButton) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController

        let alert = MDCAlertController(
            title: nil,
            message: String(format: "ConfirmOperationPrompt".localized())
        )
        alert.addAction(MDCAlertAction(title: "OK".localized(), handler: { action in
            tabBarVc.shootingTestManager.closeShootingTestEvent() { [weak self] success, error in
                guard let self = self else { return }

                if (success) {
                    self.refreshEvent()
                }
                else {
                    print("closeShootingTestEvent failed: \(error?.localizedDescription ?? String(describing: error))")
                }
            }
        }))
        alert.addAction(MDCAlertAction(title: "No".localized(), handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func reopenEventClick(_ sender: UIButton) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController

        let alert = MDCAlertController(
            title: nil,
            message: String(format: "ConfirmOperationPrompt".localized())
        )
        alert.addAction(MDCAlertAction(title: "OK".localized(), handler: { action in
            tabBarVc.shootingTestManager.reopenShootingTestEvent() { [weak self] success, error in
                guard let self = self else { return }

                if (success) {
                    self.refreshEvent()
                }
                else {
                    print("reopenShootingTestEvent failed: \(error?.localizedDescription ?? String(describing: error))")
                }
            }
        }))
        alert.addAction(MDCAlertAction(title: "No".localized(), handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func cancelEditOfficials(sender: UIButton) {
        self.setEditingOfficials(enabled: false)
    }

    @IBAction func saveEditOfficials(sender: UIButton) {
        if (self.selectedOfficials.count >= 2) {
            let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController

            tabBarVc.shootingTestManager.updateShootingTestOfficials(
                selectedOfficials: self.selectedOfficials,
                responsibleOfficialOccupationId: self.shootingTestResponsibleOccupationId
            ) { success, error in
                if (success) {
                    self.setEditingOfficials(enabled: false)
                    self.refreshEvent()
                } else {
                    print("saveEditOfficials failed: \(error?.localizedDescription ?? String(describing: error))")
                }
            }
        }
    }

    internal var isEdit: Bool = false
    internal var hasSelectedOfficials = false
    internal var hasAvailableOfficials = false

    internal var selectedOfficials: [CommonShootingTestOfficial] = Array()
    internal var availableOfficials: [CommonShootingTestOfficial] = Array()
    internal var shootingTestResponsibleOccupationId: Int64? = nil
    internal var selectedOfficialsMaster: [CommonShootingTestOfficial] = Array()
    internal var availableOfficialsMaster: [CommonShootingTestOfficial] = Array()
    internal var shootingTestResponsibleOccupationIdMaster: Int64? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        self.scrollView.autoresizingMask = .flexibleHeight
        self.setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = "ShootingTestViewTitle".localized()
        refreshEvent()
        refreshScrollViewHeight()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.setEditingOfficials(enabled: false)
    }

    @objc private func onRefreshClicked() {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        refreshEvent()
    }

    func refreshEvent() {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        tabBarVc.fetchEvent() { shootingTestEvent, error in
            self.navigationItem.rightBarButtonItem?.isEnabled = true

            if let shootingTestEvent = shootingTestEvent {
                if (shootingTestEvent.waitingToStart) {
                    self.isEdit = true
                }
                self.refreshUI(event: shootingTestEvent)

                self.refreshSelectedOfficials(event: shootingTestEvent)
                self.refreshAvailableOfficials(event: shootingTestEvent)

                self.refreshScrollViewHeight()
            } else {
                print("fetchEvent failed: \(error?.localizedDescription ?? String(describing: error))")
            }
        }
    }

    func refreshSelectedOfficials(event: CommonShootingTestCalendarEvent) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        tabBarVc.fetchSelectedOfficials() { [weak self] officials, error in
            guard let self = self else { return }

            if let officials = officials {
                self.selectedOfficialsMaster = officials
                self.hasSelectedOfficials = !officials.isEmpty
                self.shootingTestResponsibleOccupationIdMaster = officials.firstResult { official in
                    if (official.shootingTestResponsible) {
                        return official.occupationId
                    }

                    return nil
                }

                self.selectedOfficials.removeAll()
                self.selectedOfficials.insert(contentsOf: self.selectedOfficialsMaster, at: 0)
                self.shootingTestResponsibleOccupationId = self.shootingTestResponsibleOccupationIdMaster

                self.filterAvailableOfficials(event: event)
            } else {
                print("fetchSelectedOfficials failed: \(error?.localizedDescription ?? String(describing: error))")
            }
        }
    }

    func refreshAvailableOfficials(event: CommonShootingTestCalendarEvent) {
        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        tabBarVc.fetchAvailableOfficials() { [weak self] officials, error in
            guard let self = self else { return }

            if let officals = officials {
                self.availableOfficialsMaster = officals
                self.hasAvailableOfficials = !officals.isEmpty

                self.filterAvailableOfficials(event: event)
            } else {
                print("fetchAvailableOfficials failed: \(error?.localizedDescription ?? String(describing: error))")
            }
        }
    }

    private func filterAvailableOfficials(event: CommonShootingTestCalendarEvent) {
        if (self.hasAvailableOfficials && (self.hasSelectedOfficials || event.waitingToStart)) {
            self.availableOfficials.removeAll()

            for item in self.availableOfficialsMaster {
                if (!self.selectedOfficials.contains(where: {x in x.personId == item.personId})) {
                    self.availableOfficials.append(item)
                }
            }

            refreshSelectedOfficials(officials: self.selectedOfficials)
            refreshAvailableOfficials(officials: self.availableOfficials, visible: event.waitingToStart || self.isEdit)
            self.refreshScrollViewHeight()
        }
    }

    func setupUI() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "refresh_white"),
            style: .plain,
            target: self,
            action: #selector(onRefreshClicked)
        )

        self.startButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        self.editButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        self.finishButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        self.reopenButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())

        self.startButton.isUppercaseTitle = false
        self.editButton.isUppercaseTitle = false
        self.finishButton.isUppercaseTitle = false
        self.reopenButton.isUppercaseTitle = false

        self.startButton.setTitle("ShootingTestEventStart".localized(), for: .normal)
        self.editButton.setTitle("ShootingTestEventEdit".localized(), for: .normal)
        self.finishButton.setTitle("ShootingTestEventFinish".localized(), for: .normal)
        self.reopenButton.setTitle("ShootingTestEventReopen".localized(), for: .normal)

        self.officialsLabel.text = "ShootingTestOfficialsTitle".localized()

        self.saveButton.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        self.cancelButton.applyOutlinedTheme(withScheme: AppTheme.shared.secondaryButtonScheme())

        self.cancelButton.setTitle("Cancel".localized(), for: .normal)
        self.saveButton.setTitle("Save".localized(), for: .normal)
    }

    func refreshUI(event: CommonShootingTestCalendarEvent) {
        self.titleLabel.text = String(format: "%@%@ ",
                                      event.calendarEventType?.value?.localizedName ?? event.calendarEventType?.rawBackendEnumValue ?? "",
                                      event.name != nil ? "\n" + event.name! : "")
        self.dateTimeLabel.text = event.formattedDateAndTime
        self.venueLabel.text = String(format: "%@\n%@\n%@",
                                      event.venue?.name == nil ? "" : (event.venue?.name)!,
                                      event.venue?.address?.streetAddress ?? "",
                                      event.venue?.address?.city ?? "")
        self.sumOfPaymentsLabel.text = String(format: "ShootingTestTotalPaidAmount".localized(),
                                              event.formattedTotalPaidAmount)
        self.refreshButtonVisibility(event: event)
    }

    func refreshButtonVisibility(event: CommonShootingTestCalendarEvent) {
        self.startButton.isHidden = !event.waitingToStart
        self.startButtonHeightConstraint.constant = event.waitingToStart ? AppConstants.UI.ButtonHeightSmall : 0.0
        self.startButton.setNeedsLayout()

        self.editButton.isHidden = !event.ongoing && self.isEdit
        self.editButtonHeightConstraint.constant = event.ongoing && !self.isEdit ? AppConstants.UI.ButtonHeightSmall : 0.0
        self.editButton.setNeedsLayout()

        let tabBarVc = self.tabBarController as! ShootingTestTabBarViewController
        let hasEditPermission = (tabBarVc.isUserCoordinator || tabBarVc.isUserSelectedAsOfficial)
        let canCloseEvent = event.readyToClose && !self.isEdit && hasEditPermission
        self.finishButton.isHidden = !canCloseEvent
        self.finishButtonHeightConstraint.constant = canCloseEvent ? AppConstants.UI.ButtonHeightSmall : 0.0
        self.finishButton.setNeedsLayout()

        self.reopenButton.isHidden = !event.closed
        self.reopenButtonHeightConstraint.constant = event.closed ? AppConstants.UI.ButtonHeightSmall : 0.0
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
        self.buttonAreaHeightConstraint.constant = enabled ? AppConstants.UI.DefaultButtonHeight : 0

        self.availableOfficialsView.isHidden = !enabled

        refreshEvent()
    }

    func refreshAvailableOfficials(officials: [CommonShootingTestOfficial], visible: Bool) {
        self.availableOfficialsView.isHidden = !visible
        self.availableOfficialsView.axis = .vertical
        self.availableOfficialsView.distribution = .equalSpacing
        self.availableOfficialsView.alignment = .fill
        self.availableOfficialsView.spacing = 8

        self.availableOfficialsView.arrangedSubviews.forEach({ $0.removeFromSuperview() })

        officials.forEach { official in
            let view = ShootingTestOfficialView().bind(
                official: official,
                isEditing: self.isEdit,
                isSelected: false,
                isResponsible: false
            )
            view.delegate = self
            self.availableOfficialsView.addArrangedSubview(view)
        }

        self.availableOfficialsView.translatesAutoresizingMaskIntoConstraints = false
        self.availableOfficialsView.setNeedsLayout()
    }

    func refreshSelectedOfficials(officials: [CommonShootingTestOfficial]) {
        self.selectedOfficialsView.axis = .vertical
        self.selectedOfficialsView.distribution = .equalSpacing
        self.selectedOfficialsView.alignment = .fill
        self.selectedOfficialsView.spacing = 8

        self.selectedOfficialsView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        officials.forEach { official in
            let view = ShootingTestOfficialView().bind(
                official: official,
                isEditing: self.isEdit,
                isSelected: true,
                isResponsible: official.occupationId == self.shootingTestResponsibleOccupationId
            )
            view.delegate = self
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

    func onMakeOfficialResponsible(officialOccupationId: Int64) {
        self.shootingTestResponsibleOccupationId = officialOccupationId

        refreshSelectedOfficials(officials: self.selectedOfficials)
    }

    func onAddOfficial(officialOccupationId: Int64) {
        guard let officialIndex = availableOfficials.firstIndex(where: { $0.occupationId == officialOccupationId }),
              let official = availableOfficials.getOrNil(index: officialIndex) else {
            Self.logger.w { "No available official (or official index) found with occupation id \(officialOccupationId)" }
            return
        }

        selectedOfficials.append(official)
        availableOfficials.remove(at: officialIndex)

        self.refreshSelectedOfficials(officials: self.selectedOfficials)
        self.refreshAvailableOfficials(officials: self.availableOfficials, visible: true)

        self.refreshButtonsEnabled()
        self.view.layoutIfNeeded()
    }

    func onRemoveOfficial(officialOccupationId: Int64) {
        guard let officialIndex = selectedOfficials.firstIndex(where: { $0.occupationId == officialOccupationId }),
              let official = selectedOfficials.getOrNil(index: officialIndex) else {
            Self.logger.w { "No selected official (or official index) found with occupation id \(officialOccupationId)" }
            return
        }

        availableOfficials.append(official)
        selectedOfficials.remove(at: officialIndex)

        self.refreshSelectedOfficials(officials: self.selectedOfficials)
        self.refreshAvailableOfficials(officials: self.availableOfficials, visible: true)

        self.refreshButtonsEnabled()
        self.view.layoutIfNeeded()
    }
}
