import Foundation
import SnapKit
import RiistaCommon

fileprivate let CELL_TYPE = DataFieldCellType.readOnlySpeciesCode

class ReadOnlySpeciesFieldCell<FieldId : DataFieldId>: TypedDataFieldCell<FieldId, SpeciesField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    private lazy var speciesImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var speciesNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: .large, fontWeight: .medium)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private let speciesNameResolver = SpeciesInformationResolver()

    override func createSubviews(for container: UIView) {
        container.addSubview(speciesImageView)
        container.addSubview(speciesNameLabel)

        speciesImageView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.height.width.equalTo(50)
        }

        speciesNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(speciesImageView.snp.trailing).offset(16)
            make.trailing.top.bottom.equalToSuperview()
        }
    }

    override func fieldWasBound(field: SpeciesField<FieldId>) {
        if let knownSpecies = field.species as? Species.Known {
            showKnownSpecies(species: knownSpecies)
        } else if (field.species is Species.Other) {
            showOtherSpecies()
        } else if (field.species is Species.Unknown) {
            showUnknownSpecies()
        }
    }

    private func showKnownSpecies(species: Species.Known) {
        speciesImageView.image = ImageUtils.loadSpeciesImage(speciesCode: Int(species.speciesCode))
        speciesNameLabel.text = speciesNameResolver.getSpeciesName(speciesCode: species.speciesCode)
    }

    private func showOtherSpecies() {
        print("not implemented: show other species")
    }

    private func showUnknownSpecies() {
        print("not implemented: show unknown species")
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        init() {
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(ReadOnlySpeciesFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! ReadOnlySpeciesFieldCell<FieldId>

            return cell
        }
    }
}
