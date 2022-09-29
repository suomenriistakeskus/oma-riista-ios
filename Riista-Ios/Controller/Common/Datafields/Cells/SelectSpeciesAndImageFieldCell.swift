import Foundation
import SnapKit
import RiistaCommon
import MaterialComponents
import UIKit

fileprivate let CELL_TYPE = DataFieldCellType.selectSpeciesAndImage

typealias SpeciesImageClickListener<FieldId> = (_ fieldId: FieldId, _ entityImage: EntityImage?) -> Void

class SelectSpeciesAndImageFieldCell<FieldId : DataFieldId>:
    TypedDataFieldCell<FieldId, SpeciesField<FieldId>>, SpeciesSelectionDelegate {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private lazy var topLevelContainer: OverlayStackView = {
        let container = OverlayStackView()
        container.axis = .horizontal
        container.alignment = .center

        container.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }
        return container
    }()

    override var containerView: UIView {
        topLevelContainer
    }

    private lazy var speciesButton: MDCButton = {
        let button = MDCButton(type: .custom)
        AppTheme.shared.setupSpeciesButtonTheme(button: button)
        button.contentHorizontalAlignment = .left
        button.contentVerticalAlignment = .center

        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }

        button.addTarget(self, action: #selector(selectSpeciesClicked), for: .touchUpInside)

        return button
    }()

    private lazy var imagesButton: MDCButton = {
        let button = MDCButton(type: .custom)
        AppTheme.shared.setupImagesButtonTheme(button: button)

        button.snp.makeConstraints { make in
            make.height.width.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }

        button.addTarget(self, action: #selector(imagesClicked), for: .touchUpInside)

        return button
    }()

    private let speciesNameResolver = SpeciesInformationResolver()
    private var speciesEventDispatcher: SpeciesEventDispatcher?
    private var speciesImageClickListener: SpeciesImageClickListener<FieldId>?
    private weak var navigationControllerProvider: ProvidesNavigationController?

    private lazy var dialogTransitionController: MDCDialogTransitionController = {
        MDCDialogTransitionController()
    }()

    override func createSubviews(for container: UIView) {
        guard let container = container as? OverlayStackView else {
            fatalError("Expected OverlayStackView as container!")
        }

        container.addView(speciesButton)
        container.addSpacer(size: 12, canExpand: false)
        container.addView(imagesButton)
    }

    override func fieldWasBound(field: SpeciesField<FieldId>) {
        speciesButton.setEnabled(!field.settings.readOnly, animated: false)

        if let knownSpecies = field.species as? Species.Known {
            showKnownSpecies(species: knownSpecies)
            updateSpeciesButton(knownSpecies: true)
        } else if (field.species is Species.Other) {
            let tintColor: UIColor? = field.settings.readOnly ? .black : nil
            showOtherSpecies(tintColor: tintColor)
            updateSpeciesButton(knownSpecies: false)
        } else if (field.species is Species.Unknown) {
            showUnknownSpecies()
            updateSpeciesButton(knownSpecies: false)
        }
        updateImagesButton()
    }

    private func showKnownSpecies(species: Species.Known) {
        speciesButton.setTitle(speciesNameResolver.getSpeciesName(speciesCode: species.speciesCode), for: .normal)
        speciesButton.setImage(
            ImageUtils.loadSpeciesImage(speciesCode: Int(species.speciesCode),
                                        size: CGSize(width: 42, height: 42)),
            for: .normal
        )
        self.speciesButton.imageView?.tintColor = nil
    }

    private func showOtherSpecies(tintColor: UIColor?) {
        let image = unknownImageBasedOnTintColor(tintColor: tintColor)
        speciesButton.setTitle("SrvaOtherSpeciesDescription".localized(), for: .normal)
        speciesButton.setImage(image, for: .normal)
        self.speciesButton.imageView?.tintColor = tintColor
    }

    private func unknownImageBasedOnTintColor(tintColor: UIColor?) -> UIImage? {
        if (tintColor == nil) {
            return UIImage(named: "unknown_white")
        } else {
            return UIImage(named: "unknown_white")?.withRenderingMode(.alwaysTemplate)
        }
    }

    private func showUnknownSpecies() {
        speciesButton.setTitle("SrvaUnknownSpeciesDescription".localized(), for: .normal)
        speciesButton.setImage(UIImage(named: "unknown_white"), for: .normal)
        self.speciesButton.imageView?.tintColor = nil
    }

    func updateSpeciesButton(knownSpecies: Bool) {
        speciesButton.imageEdgeInsets = UIEdgeInsets(
            top: speciesButton.imageEdgeInsets.top,
            left: knownSpecies ? -12 : 0,
            bottom: speciesButton.imageEdgeInsets.bottom,
            right: speciesButton.imageEdgeInsets.right
        )
        speciesButton.titleEdgeInsets = UIEdgeInsets(
            top: self.speciesButton.titleEdgeInsets.top,
            left: knownSpecies ? 0 : 16,
            bottom: self.speciesButton.titleEdgeInsets.bottom,
            right: self.speciesButton.titleEdgeInsets.right
        )
        self.speciesButton.imageView?.layer.cornerRadius = 3;
    }

    func updateImagesButton() {
        let delegate = UIApplication.shared.delegate as! RiistaAppDelegate
        let context = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        context.parent = delegate.managedObjectContext

        guard let diaryImage = boundField?.entityImage?.toDiaryImage(context: context) else {
            imagesButton.setImage(UIImage(named: "camera"), for: .normal)
            return
        }

        ImageUtils.loadDiaryImage(
            diaryImage,
            options: ImageLoadOptions.aspectFilled(
                size: CGSize(width: AppConstants.UI.ButtonHeightSmall, height: AppConstants.UI.ButtonHeightSmall)
            ),
            onSuccess: { [self] image in
                self.imagesButton.setImageLoadedSuccessfully()
                self.imagesButton.setBackgroundImage(image, for: .normal)
                self.imagesButton.setImage(nil, for: .normal)
                self.imagesButton.setBorderWidth(0, for: .normal)
            },
            onFailure: { [self] reason in
                var displayedIcon: UIImage? = nil
                if (boundField?.settings.readOnly ?? true) {
                    displayedIcon = UIImage(named: "missing-image-error")?.withRenderingMode(.alwaysTemplate)
                } else {
                    displayedIcon = UIImage(named: "camera")?.withRenderingMode(.alwaysTemplate)
                }
                self.imagesButton.setImage(displayedIcon, for: .normal)
                self.imagesButton.setImageTintColor(UIColor.white, for: .normal)
                self.imagesButton.setBackgroundImage(nil, for: .normal)
                self.imagesButton.setImageLoadFailed(reason: reason)
            })
    }

    @objc private func selectSpeciesClicked() {
        guard let field = boundField else {
            print("No bound field, cannot determine species selection configuration")
            return
        }

        if let listedSpecies = field.settings.selectableSpecies as? SpeciesFieldSelectableSpecies.Listed {
            selectFromListedSpecies(listedSpecies: listedSpecies)
        } else {
            selectSpeciesCategoryAndSpecies()
        }
    }

    private func selectFromListedSpecies(listedSpecies: SpeciesFieldSelectableSpecies.Listed) {
        guard let navigationController = self.navigationControllerProvider?.navigationController else {
            print("No navigation controller, cannot open species selection!")
            return
        }

        let storyboard = UIStoryboard(name: "DetailsStoryboard", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "speciesSelectController") as! RiistaSpeciesSelectViewController
        controller.delegate = self
        controller.values = listedSpecies.species.compactMap { species in
            guard let speciesCode = species.knownSpeciesCodeOrNull() else {
                return nil
            }
            return RiistaGameDatabase.sharedInstance().species(byId: speciesCode.intValue)
        }

        let containsOtherSpecies = listedSpecies.species.contains { species in
            species is Species.Other
        }
        controller.showOther = NSNumber(value: containsOtherSpecies)
        navigationController.pushViewController(controller, animated: true)
    }

    private func selectSpeciesCategoryAndSpecies() {
        guard let navigationController = self.navigationControllerProvider?.navigationController else {
            print("No navigation controller, cannot open species selection!")
            return
        }

        let dialogController = SpeciesCategoryDialogController()
        dialogController.modalPresentationStyle = .custom
        dialogController.transitioningDelegate = self.dialogTransitionController

        dialogController.completionHandler = { [weak self] categoryCode in
            if (categoryCode < 1 || categoryCode > 3) {
                print("Invalid category selected, refusing to continue species selection")
                return
            }

            let storyboard = UIStoryboard(name: "DetailsStoryboard", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "speciesSelectController") as! RiistaSpeciesSelectViewController
            controller.delegate = self
            if let category = RiistaGameDatabase.sharedInstance().categories[categoryCode] as? RiistaSpeciesCategory {
                controller.category = category
            }
            navigationController.pushViewController(controller, animated: true)
        }

        navigationController.present(dialogController, animated: true)
    }

    @objc private func imagesClicked() {
        guard let fieldId = boundField?.id_ else {
            return
        }
        speciesImageClickListener?(fieldId, boundField?.entityImage)
    }

    func speciesSelected(_ species: RiistaSpecies) {
        guard let fieldId = boundField?.id_ else {
            return
        }

        if (species.speciesId != -1) {
            speciesEventDispatcher?.dispatchSpeciesChanged(fieldId: fieldId, value: Species.Known(speciesCode: Int32(species.speciesId)))
        } else {
            speciesEventDispatcher?.dispatchSpeciesChanged(fieldId: fieldId, value: Species.Other())
        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {

        private weak var navigationControllerProvider: ProvidesNavigationController?
        private var speciesEventDispatcher: SpeciesEventDispatcher?
        private var speciesImageClickListener: SpeciesImageClickListener<FieldId>?

        init(
            navigationControllerProvider: ProvidesNavigationController?,
            speciesEventDispatcher: SpeciesEventDispatcher?,
            speciesImageClickListener: SpeciesImageClickListener<FieldId>?
        ) {
            self.navigationControllerProvider = navigationControllerProvider
            self.speciesEventDispatcher = speciesEventDispatcher
            self.speciesImageClickListener = speciesImageClickListener
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(SelectSpeciesAndImageFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! SelectSpeciesAndImageFieldCell<FieldId>

            cell.navigationControllerProvider = navigationControllerProvider
            cell.speciesEventDispatcher = speciesEventDispatcher
            cell.speciesImageClickListener = speciesImageClickListener

            return cell
        }
    }
}
