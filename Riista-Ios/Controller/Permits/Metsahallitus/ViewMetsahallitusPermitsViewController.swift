import Foundation
import UIKit
import MaterialComponents.MaterialDialogs
import SnapKit
import RiistaCommon


class ViewMetsahallitusPermitViewController:
    BaseControllerWithViewModel<ViewMetsahallitusPermitViewModel, ViewMetsahallitusPermitController>,
    ProvidesNavigationController {

    private let permitIdentifier: String

    private lazy var _controller: ViewMetsahallitusPermitController = {
        ViewMetsahallitusPermitController(
            permitIdentifier: permitIdentifier,
            usernameProvider: RiistaSDK.shared.currentUserContext,
            permitProvider: RiistaSDK.shared.metsahallitusPermits
        )
    }()

    override var controller: ViewMetsahallitusPermitController {
        get {
            _controller
        }
    }

    private lazy var permitTypeAndIdentifierLabel: UILabel = {
        let label = UILabel().configure(
            fontSize: .medium,
            fontWeight: .semibold,
            textAlignment: .left,
            numberOfLines: 0
        )
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var permitAreaCodeAndNameLabel: UILabel = {
        let label = UILabel().configure(
            fontSize: .medium,
            fontWeight: .semibold,
            textColor: UIColor.applicationColor(Primary)
        )
        return label
    }()

    private lazy var permitNameLabel: UILabel = {
        let label = UILabel().configure(
            fontSize: .medium,
            fontWeight: .semibold
        )
        return label
    }()

    private lazy var permitPeriodLabel: UILabel = {
        let label = UILabel().configure(
            fontSize: .medium,
            fontWeight: .semibold
        )
        return label
    }()

    private lazy var harvestFeedbackButton: CustomizableMaterialButton = {
        let button = CustomizableMaterialButton(
            config: CustomizableMaterialButtonConfig { config in
                config.setupTheme = { btn in
                    btn.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
                }
                config.backgroundColor = nil // clear so that theming is visible
                config.titleTextColor = .white
                config.titleTextTransform = { text in
                    text?.uppercased(with: RiistaSettings.locale())
                }
                config.horizontalSpacing = 4
                config.reserveSpaceForTrailingIcon = true
                config.trailingIconSize = CGSize(width: 24, height: 24)
            }
        )

        button.trailingIcon = UIImage(named: "open_in_browser")
        button.trailingIconImageView.tintColor = .white
        button.setTitle("MetsahallitusPermitHarvestFeedback".localized(), for: .normal)

        button.onClicked = {
            self.confirmSendHarvestFeedback()
        }
        return button
    }()

    private let languageProvider = CurrentLanguageProvider()

    init(permitIdentifier: String) {
        self.permitIdentifier = permitIdentifier
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    override func loadView() {
        super.loadView()

        let container = TwoColumnStackView()
        container.spacing = 8
        container.spacingBetweenColumns = 16

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AppConstants.UI.DefaultHorizontalInset)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(8)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        container.addView(permitTypeAndIdentifierLabel, spaceAfter: 8)

        container.addRow(row: createRow(labelKey: "MetsahallitusPermitArea", valueView: permitAreaCodeAndNameLabel))
        container.addRow(row: createRow(labelKey: "MetsahallitusPermitName", valueView: permitNameLabel))
        container.addRow(row: createRow(labelKey: "MetsahallitusPermitPeriod", valueView: permitPeriodLabel))

        container.addView(harvestFeedbackButton, spaceBefore: 12)
        harvestFeedbackButton.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }

        container.addSpacer(size: 0, canExpand: true)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "MetsahallitusPermitTitle".localized()
    }

    override func onViewModelLoaded(viewModel: ViewMetsahallitusPermitViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)

        let permit = viewModel.permit

        let permitType = permit.permitType.localizedWithFallbacks(
            languageProvider: languageProvider
        ) ?? "MetsahallitusPermitCardTitle".localized()

        permitTypeAndIdentifierLabel.setTextAllowingOrphanLines(text: "\(permitType), \(permit.permitIdentifier)")

        if let areaName = permit.areaName.localizedWithFallbacks(languageProvider: languageProvider) {
            permitAreaCodeAndNameLabel.text = "\(permit.areaNumber) \(areaName)"
        } else {
            permitAreaCodeAndNameLabel.text = "\(permit.areaNumber)"
        }

        permitNameLabel.text = permit.permitName.localizedWithFallbacks(languageProvider: languageProvider)
        permitPeriodLabel.text = permit.formattedPeriodDates

        if (permit.harvestFeedbackUrl?.localizedWithFallbacks(languageProvider: languageProvider) != nil) {
            harvestFeedbackButton.isHidden = false
        } else {
            harvestFeedbackButton.isHidden = true
        }
    }

    private func confirmSendHarvestFeedback() {
        let alert = MDCAlertController(title: "AlertTitle".localized(),
                                       message: "MetsahallitusPermitFeedbackAlertMessage".localized())
        let cancelAction = MDCAlertAction(title: "CancelRemove".localized(), handler: nil)
        let confirmAction = MDCAlertAction(title: "Ok".localized()) { _ in
            self.sendHarvestFeedback()
        }

        alert.addAction(cancelAction)
        alert.addAction(confirmAction)

        present(alert, animated: true, completion: nil)
    }

    private func sendHarvestFeedback() {
        guard let permit = controller.getLoadedViewModelOrNull()?.permit else {
            return
        }
        let harvestFeedbackUrlString = permit.harvestFeedbackUrl?.localizedWithFallbacks(languageProvider: languageProvider)
        guard let harvestFeedbackUrlString = harvestFeedbackUrlString,
              let harvestFeedbackUrl = URL(string: harvestFeedbackUrlString) else {
            return
        }

        UIApplication.shared.open(harvestFeedbackUrl, options: [:], completionHandler: nil)
    }

    private func createRow(labelKey: String, valueView: UIView) -> TwoColumnRowView {
        let label = UILabel().configure(for: .label)
        label.text = labelKey.localized()
        return TwoColumnRowView(firstColumnView: label, secondColumnView: valueView)
    }
}
