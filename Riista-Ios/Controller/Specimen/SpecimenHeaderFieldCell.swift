import Foundation
import RiistaCommon
import UIKit

fileprivate let CELL_TYPE = DataFieldCellType.labelCaption
fileprivate let REMOVE_IMAGE = UIImage(named: "cancel")?.withRenderingMode(.alwaysTemplate)

class SpecimenHeaderFieldCell<FieldId : DataFieldId>:
    TypedDataFieldCell<FieldId, LabelField<FieldId>> {

    override var cellType: DataFieldCellType { CELL_TYPE }

    var clickHandler: OnButtonClicked<FieldId>? = nil

    private let captionView = CaptionView()

    private lazy var removeButton: UIButton = {
        let button = UIButton()

        let imageView = UIImageView()
        imageView.image = REMOVE_IMAGE
        imageView.tintColor = UIColor.applicationColor(Destructive)
        button.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.centerY.trailing.equalToSuperview()
            make.width.height.equalTo(24)
        }
        button.addTarget(self, action: #selector(handleButtonClick), for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
            make.width.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return button
    }()

    override func createSubviews(for container: UIView) {
        container.addSubview(captionView)
        container.addSubview(removeButton)
        captionView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(removeButton.snp.left)
        }
        removeButton.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
        }
    }

    override func fieldWasBound(field: LabelField<FieldId>) {
        captionView.text = field.text
    }

    @objc private func handleButtonClick() {
        guard let field = boundField else {
            return
        }

        clickHandler?(field.id_)
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {
        var clickHandler: OnButtonClicked<FieldId>? = nil

        init(clickHandler: OnButtonClicked<FieldId>?) {
            self.clickHandler = clickHandler
            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(SpecimenHeaderFieldCell<FieldId>.self, forCellReuseIdentifier: CELL_TYPE.reuseIdentifier)
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! SpecimenHeaderFieldCell<FieldId>

            cell.clickHandler = clickHandler

            return cell
        }
    }
}
