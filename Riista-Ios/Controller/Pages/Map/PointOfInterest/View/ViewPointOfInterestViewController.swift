import Foundation
import UIKit
import SnapKit
import RiistaCommon


class ViewPointOfInterestViewController:
    BaseControllerWithViewModel<PoiLocationsViewModel, PoiLocationController>,
    ProvidesNavigationController,
    PointsOfInterestCollectionViewListener {

    private let areaExternalId: String
    private let pointOfInterestGroupId: Int64
    private let initiallySelectedPointOfInterestId: Int64

    private lazy var _controller: RiistaCommon.PoiLocationController = {
        RiistaCommon.PoiLocationController(
            locationGroupContext: RiistaSDK.shared.poiContext.getPoiLocationGroupContext(externalId: areaExternalId),
            poiLocationGroupId: pointOfInterestGroupId,
            initiallySelectedPoiLocationId: initiallySelectedPointOfInterestId
        )
    }()

    override var controller: PoiLocationController {
        get {
            _controller
        }
    }

    private let localizedStringProvider = LocalizedStringProvider()

    private lazy var pointsOfInterestView: PointsOfInterestCollectionView = {
        let view = PointsOfInterestCollectionView()
        view.listener = self
        view.navigationControllerProvider = self
        return view
    }()

    private lazy var buttonArea: UIView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = 8
        view.backgroundColor = UIColor.applicationColor(ViewBackground)
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = AppConstants.UI.DefaultEdgeInsets

        view.addArrangedSubview(previousButton)
        view.addArrangedSubview(nextButton)
        view.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall + view.layoutMargins.top + view.layoutMargins.bottom)
        }

        let separator = SeparatorView(orientation: .horizontal)
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        return view
    }()

    private lazy var previousButton: CustomizableMaterialButton = {
        let btn = CustomizableMaterialButton(
            config: PREV_NEXT_BUTTON_CONFIG.configure { config in
                config.titleTextAlignment = .left
            }
        )
        btn.leadingIcon = UIImage(named: "arrow_left")?.withRenderingMode(.alwaysTemplate)
        btn.setTitle("Previous".localized(), for: .normal)
        btn.updateLayoutMargins(left: 0)
        btn.onClicked = { [weak self] in
            self?.onPreviousPointOfInterestClicked()
        }
        return btn
    }()

    private(set) lazy var nextButton: CustomizableMaterialButton = {
        let btn = CustomizableMaterialButton(
            config: PREV_NEXT_BUTTON_CONFIG.configure { config in
                config.titleTextAlignment = .right
            }
        )
        btn.trailingIcon = UIImage(named: "arrow_right")?.withRenderingMode(.alwaysTemplate)
        btn.setTitle("Next".localized(), for: .normal)
        btn.updateLayoutMargins(right: 0)
        btn.onClicked = { [weak self] in
            self?.onNextPointOfInterestClicked()
        }
        return btn
    }()


    init(areaExternalId: String, pointOfInterestGroupId: Int64, pointOfInterestId: Int64) {
        self.areaExternalId = areaExternalId
        self.pointOfInterestGroupId = pointOfInterestGroupId
        self.initiallySelectedPointOfInterestId = pointOfInterestId

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) is not supported")
    }

    private func onPreviousPointOfInterestClicked() {
        guard let viewModel = controller.getLoadedViewModelOrNull() else {
            return
        }

        controller.eventDispatcher.dispatchPoiLocationSelected(index: viewModel.selectedIndex - 1)
    }

    private func onNextPointOfInterestClicked() {
        guard let viewModel = controller.getLoadedViewModelOrNull() else {
            return
        }

        controller.eventDispatcher.dispatchPoiLocationSelected(index: viewModel.selectedIndex + 1)
    }

    override func loadView() {
        super.loadView()

        view.addSubview(pointsOfInterestView)
        view.addSubview(buttonArea)
        pointsOfInterestView.snp.makeConstraints { make in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(buttonArea.snp.top)
        }

        buttonArea.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "" // will be updated once we have loaded the POIs
    }

    private func updatePreviousNextButtonStatuses(viewModel: PoiLocationsViewModel) {
        previousButton.isEnabled = viewModel.selectedIndex > 0
        nextButton.isEnabled = viewModel.selectedIndex < (viewModel.poiLocations.count - 1)
    }

    private func updateTitle(viewModel: PoiLocationsViewModel) {
        if (viewModel.poiLocations.isEmpty) {
            title = ""
            return
        }

        let selectedPoi = viewModel.poiLocations[Int(viewModel.selectedIndex)]

        let poiGroupTypeString = selectedPoi.groupType.localized(stringProvider: localizedStringProvider)
        title = "\(poiGroupTypeString): \(selectedPoi.groupVisibleId)-\(selectedPoi.visibleId)"
    }

    override func onViewModelLoaded(viewModel: PoiLocationsViewModel) {
        super.onViewModelLoaded(viewModel: viewModel)
        updatePreviousNextButtonStatuses(viewModel: viewModel)
        updateTitle(viewModel: viewModel)
        pointsOfInterestView.updatePointsOfInterest(poiLocationsViewModel: viewModel)
    }

    override func onViewModelLoadFailed() {
        super.onViewModelLoadFailed()
    }


    // MARK: - PointsOfInterestCollectionViewListener

    func onSelectedPointOfInterestChanged(selectedPoiIndex: Int) {
        controller.eventDispatcher.dispatchPoiLocationSelected(index: Int32(selectedPoiIndex))
    }
}


fileprivate let PREV_NEXT_BUTTON_CONFIG = CustomizableMaterialButtonConfig { config in
    config.titleTextColor = UIColor.applicationColor(Primary)
    config.titleTextTransform = { text in
        // don't alter text
        text
    }
    config.horizontalSpacing = 12
    config.titleTextAlignment = .left
}
