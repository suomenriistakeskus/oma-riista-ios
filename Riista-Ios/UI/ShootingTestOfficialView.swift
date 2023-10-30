import UIKit
import MaterialComponents.MaterialButtons
import RiistaCommon
import SnapKit

protocol OfficialViewDelegate {
    func onMakeOfficialResponsible(officialOccupationId: Int64)
    func onAddOfficial(officialOccupationId: Int64)
    func onRemoveOfficial(officialOccupationId: Int64)
}

class ShootingTestOfficialView: UIView {
    private(set) lazy var nameLabel: UILabel = UILabel().configure(
        for: .label,
        numberOfLines: 0
    )

    private(set) lazy var makeResponsibleButton: MaterialButton = {
        let btn = MaterialButton()
        btn.applyTextTheme(withScheme: AppTheme.shared.imageButtonScheme())
        btn.contentEdgeInsets = .zero
        btn.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.contentHorizontalAlignment = .fill
        btn.contentVerticalAlignment = .fill

        btn.snp.makeConstraints { make in
            make.height.width.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }
        btn.setImageTintColor(UIColor.applicationColor(Primary), for: .normal)
        // draw using primary color even if disabled
        btn.setImageTintColor(UIColor.applicationColor(Primary), for: .disabled)
        // don't fade image if disabled
        btn.adjustsImageWhenDisabled = false

        return btn
    }()

    private(set) lazy var actionButton: MaterialButton = {
        let btn = MaterialButton()
        btn.isUppercaseTitle = false
        btn.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
            actionButtonWidthConstraint = make.width.equalTo(0)
                .offset(ADD_REMOVE_BUTTON_WIDTH)
                .priority(999)
                .constraint
        }
        return btn
    }()

    private var actionButtonWidthConstraint: Constraint?

    var delegate: OfficialViewDelegate?

    init() {
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    @discardableResult
    func bind(
        official: CommonShootingTestOfficial,
        isEditing: Bool,
        isSelected: Bool,
        isResponsible: Bool
    ) -> Self {
        nameLabel.text = String(
            format: "%@ %@",
            official.lastName ?? "",
            official.firstName ?? ""
        )

        setupMakeResponsibleButton(
            official: official,
            isEditing: isEditing,
            isSelected: isSelected,
            isResponsible: isResponsible
        )

        setupActionButton(
            official: official,
            isEditing: isEditing,
            isSelected: isSelected
        )

        return self
    }

    private func setupMakeResponsibleButton(
        official: CommonShootingTestOfficial,
        isEditing: Bool,
        isSelected: Bool,
        isResponsible: Bool
    ) {
        if (!isSelected) {
            makeResponsibleButton.isHidden = true
            return
        }

        makeResponsibleButton.isHidden = false
        makeResponsibleButton.isEnabled = isEditing

        if (isResponsible) {
            makeResponsibleButton.setImage(ICON_STAR_FILLED, for: .normal)
        } else {
            makeResponsibleButton.setImage(ICON_STAR, for: .normal)
            makeResponsibleButton.onClicked = {
                self.delegate?.onMakeOfficialResponsible(officialOccupationId: official.occupationId)
            }
        }
    }

    private func setupActionButton(
        official: CommonShootingTestOfficial,
        isEditing: Bool,
        isSelected: Bool
    ) {
        if (!isEditing) {
            actionButton.isHidden = true
            actionButtonWidthConstraint?.update(offset: 0)
            return
        }

        actionButton.isHidden = false
        actionButtonWidthConstraint?.update(offset: ADD_REMOVE_BUTTON_WIDTH)

        if (isSelected) {
            actionButton.applyOutlinedTheme(withScheme: AppTheme.shared.outlineButtonScheme())
            actionButton.setTitle("ShootingTestOfficialRemove".localized(), for: .normal)

            actionButton.onClicked = {
                self.delegate?.onRemoveOfficial(officialOccupationId: official.occupationId)
            }
        } else {
            actionButton.applyContainedTheme(withScheme: AppTheme.shared.outlineButtonScheme())
            actionButton.setTitle("ShootingTestOfficialAdd".localized(), for: .normal)

            actionButton.onClicked = {
                self.delegate?.onAddOfficial(officialOccupationId: official.occupationId)
            }
        }
    }

    private func commonInit() {
        addSubview(nameLabel)

        addSubview(makeResponsibleButton)
        addSubview(actionButton)

        nameLabel.snp.makeConstraints { make in
            make.leading.top.bottom.height.equalToSuperview()
            make.trailing.lessThanOrEqualTo(makeResponsibleButton.snp.leading).offset(-8)
        }

        makeResponsibleButton.snp.makeConstraints { make in
            make.centerY.equalTo(actionButton.snp.centerY)
            make.trailing.equalTo(actionButton.snp.leading).offset(-8).priority(999)
        }

        actionButton.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
        }
    }
}


fileprivate let ICON_STAR = UIImage(named: "star")
fileprivate let ICON_STAR_FILLED = UIImage(named: "star-filled")
fileprivate let ADD_REMOVE_BUTTON_WIDTH: CGFloat = 100
