import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.instructions

class InstructionsFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, InstructionsField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private lazy var instructionsButton: MaterialButton = {
        let button = MaterialButton()
        button.applyTextTheme(withScheme: AppTheme.shared.textButtonScheme())

        let questionMarkSize: CGFloat = 32.0
        let imageView = UIImageView().apply { imageView in
            imageView.layer.cornerRadius = questionMarkSize / 2
            imageView.backgroundColor = UIColor.applicationColor(Primary)
            imageView.image = UIImage(named: "unknown_white")
        }

        button.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(questionMarkSize)
        }

        let titleLabel = UILabel().apply { label in
            label.font = UIFont.appFont(for: .title, fontWeight: .semibold)
            label.textColor = UIColor.applicationColor(Primary)
            label.text = "Instructions".localized()
        }
        button.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(12)
            make.trailing.centerY.equalToSuperview()
        }

        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }

        button.onClicked = { [weak self] in
            self?.showInstructions()
        }
        return button
    }()

    override var containerView: UIView {
        return instructionsButton
    }

    weak var navigationControllerProvider: ProvidesNavigationController?

    override func createSubviews(for container: UIView) {
        // nop
    }

    private func showInstructions() {
        guard let navigatorProvider = navigationControllerProvider,
              let speciesCode = boundField?.type.getRelatedSpeciesCode() else {
            print("Cannot display instructions, pre-requisites not met")
            return
        }

        let instructions = AntlerInstructions.getInstructionsFor(speciesCode: speciesCode)
        if (instructions.count == 0) {
            print("No instructions for species \(speciesCode)!")
            return
        }

        guard let species = RiistaGameDatabase.sharedInstance().species(byId: speciesCode) else {
            print("No species found for species \(speciesCode)")
            return
        }

        let storyboard = UIStoryboard(name: "HarvestStoryboard", bundle: nil)
        guard let containerViewController = storyboard.instantiateViewController(withIdentifier: "InstructionsControllerContainer") as? UINavigationController else {
            print("Could not instantiate container viewcontroller for instructions!")
            return
        }
        guard let instructionsViewController = containerViewController.rootViewController as? InstructionsViewController else {
            print("Could not obtain instructions viewcontroller")
            return
        }
        instructionsViewController.title = String(
            format: "InstructionsFormat".localized(),
            RiistaUtils.name(withPreferredLanguage: species.name)
        )
        instructionsViewController.instructionsItems = instructions
        instructionsViewController.modalPresentationStyle = .popover

        navigatorProvider.navigationController?.present(containerViewController, animated: true, completion: nil)
    }


    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        weak var navigationControllerProvider: ProvidesNavigationController?

        init(navigationControllerProvider: ProvidesNavigationController?) {
            self.navigationControllerProvider = navigationControllerProvider
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(InstructionsFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! InstructionsFieldCell<FieldId>

            cell.navigationControllerProvider = navigationControllerProvider

            return cell
        }
    }
}

fileprivate extension InstructionsFieldType {
    func getRelatedSpeciesCode() -> Int? {
        switch self {
        case .mooseAntlerInstructions:              return AppConstants.SpeciesCode.Moose
        case .whiteTailedDeerAntlerInstructions:    return AppConstants.SpeciesCode.WhiteTailedDeer
        case .roeDeerAntlerInstructions:            return AppConstants.SpeciesCode.RoeDeer
        default:
            print("Unknown instructions observed")
            return nil
        }
    }
}
